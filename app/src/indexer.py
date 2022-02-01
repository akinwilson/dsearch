import json
import os
import re
import pandas as pd
import meilisearch
from meilisearch.errors import *

import pickle 
from pathlib import Path 
import time
from pprint import pprint
from pathlib import Path
import subprocess
import requests
import logging 
from requests.exceptions import *
import numpy as np 

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.info("Initialised indexer")
# DB path set to  be the elastic file system.

###########################
DB_PATH = "mnt/efs"
###########################


class Preprocessor:
    def __init__(self):
        self.root = Path("/home/akinwilson/data/mana/quora/quora")
        self.dfu = self.user_formatting() 
        self.dfq = self.question_formatting()
        self.total_dict = self.primary_id_formatting()
        self.total_records = {k:self.df_to_records(v) for k,v in self.total_dict.items()}
    
    def question_formatting(self):
        q = pickle.load(open(self.root / "qa-info.p", "rb"))
        def profile_formatting(q):
            q.a_profile_url = q.a_profile_url.str.split("profile/").str[-1]
            q.a_profile_url= q.a_profile_url.apply( lambda x: re.sub('[0-9].*', '', x)) 
            q.a_profile_url = q.a_profile_url.str.split("-").apply(lambda x : " ".join(x))
            q.rename(columns={"a_profile_url":"profile"}, inplace=True)
            return q
        def q_text_formatting(q):
            q.question_url = q.question_url.str.split("m/").str[-1]
            q.question_url = q.question_url.str.replace("-", " ")
            q.rename(columns={"question_url":"question"},inplace=True)
            return q
        def tags_formatting(q):
            q.tags = q.tags.apply(lambda x: [str(re.sub("-", " ", y)) for y in  x] )
            q.tags = q.tags.apply( lambda x: [re.sub('[0-9].*', '', y) for y in x])
            return q     
        dfq = q_text_formatting(tags_formatting(profile_formatting(q)))[['profile','tags', 'question']].drop_duplicates(subset=['question']).dropna()        
    
        dfq['id'] = np.arange(0,dfq.shape[0])
        return dfq

    def user_formatting(self):
        u = pickle.load(open(self.root / "user-info.p", "rb")) 
        def profile_formatting(u):
            u.profile_url = u.profile_url.str.split("profile/").str[-1]
            u.profile_url= u.profile_url.apply( lambda x: re.sub('[0-9].*', '', x)) 
            u.profile_url = u.profile_url.str.split("-").apply(lambda x : " ".join(x))
            u.rename(columns={"profile_url":"profile"}, inplace=True)
            return u 
        def bio_formatting(u):
            u.bio  = u.bio.apply(lambda x: str(x[0]) if len(x) > 0 else "")
            u.bio = u.bio.replace("None", "")
            return u 
        def topic_formatting(u):
            u.topic_url = u.topic_url.apply( lambda x: [y.split("topic/")[-1] for y in x])
            u.topic_url = u.topic_url.apply(lambda x: [str(re.sub("-", " ", y)) for y in  x] )
            u.topic_url = u.topic_url.apply(lambda x: [y for y in x if y !="None"])
            u.rename(columns={"topic_url":"topic"}, inplace=True)
            return u 
        dfu = topic_formatting(bio_formatting(profile_formatting(u)))[['profile','bio',"topic"]]
        dfu['id'] = np.arange(0,dfu.shape[0])
        return  dfu


    def primary_id_formatting(self):
        function_dict = {
            "user": self.dfu,
            "question": self.dfq
        }
        for (k,v) in function_dict.items():
            function_dict[k]["id"] = function_dict[k].id.apply( lambda i: str(i) + "_" + k )
        function_dict['global']  =  pd.concat(list(function_dict.values()))   
        return function_dict  

    def df_to_records(self, df):
        df  = df.to_json(orient="records")
        return df 
    
    def df_to_json(self, index):
        return json.loads(self.total_records[index])





class MeiliClientIndexer:
    def __init__(self):
        self.meili_engine_initialisation()
        address = os.environ["MEILI_HTTP_ADDR"]
        add_health = address + "/health"
        master_key = os.environ["MEILI_MASTER_KEY"]
        try:
            self.client = meilisearch.Client("http://" + address, master_key)
        except (ConnectionError, MissingSchema) as e:
            try:
                self.client = meilisearch.Client("https://" + address, master_key)
            except (ConnectionError or MissingSchema) as e:
                self.client = meilisearch.Client(address, master_key)
                logger.log(msg=
                    "Tried every variation to AWS url; http, htttps and no protocol specification"
                )
                pass
            pass

    def meili_engine_initialisation(self):
        WAIT = 3
        subprocess.call([f"meilisearch --db-path {DB_PATH}&"], shell=True)
        time.sleep(WAIT)
        client = meilisearch.Client(
            "http://" + os.environ["MEILI_HTTP_ADDR"], os.environ["MEILI_MASTER_KEY"]
        )
        logger.log(msg=f"health status after waiting for {WAIT}s : {client.health()["status"]}")

    def indexing(self, index, json_records):

        self.client.delete_index_if_exists(index)
        self.index = self.client.index(index)
        self.index.add_documents(json_records)
        time.sleep(2)

    def update_index_settings(self, index, json_config):
        self.client.index(index).update_settings(json_config)


def handler(event, lambda_context):
    # Init the meilisearch engine for the purpose of producing the data.ms file.
    indexes = ["user", "question", "global"]
    root = str(Path(Path().cwd()) / "configurations")
    config_files = [os.path.join(root, file) for file in os.listdir(root)]
    s = time.time()
    convertor = Preprocessor()
    f = time.time()
    logger.log(msg=f"DB2Json().__init__(): {f - s} seconds")
    indexer = MeiliClientIndexer()

    for INDEX_NAME in indexes:
        s = time.time()
        input_json = convertor.df_to_json(INDEX_NAME)
        f = time.time()
        logger.log(msg=f"DB2Json().df_to_json({INDEX_NAME}): {f - s} seconds")
        # Loading configuration file for index
        try:
            config_file_path = [file for file in config_files if INDEX_NAME in file][0]
        except IndexError:
            logger.log(msg="cannot find configuration files")
            pass
        logger.log(msg=f"prining config_file_path: {config_file_path}")

        with open(config_file_path, "r") as file:
            config = json.loads(file.read())



        indexer.client.delete_index_if_exists(uid=INDEX_NAME)
        r = indexer.client.create_index(uid=INDEX_NAME, options={"primaryKey": "id"})
        logger.log(msg=f"Response following indexing: {r.__dict__}")
        s = time.time()
        indexer.indexing(index=INDEX_NAME, json_records=input_json)
        f = time.time()
        logger.log(msg=f"MeiliClientIndexer().indexing('item',{INDEX_NAME}): {f - s} seconds")

    ##################################################################################
    # logger.log(msg="The current dirctory is: ", os.getcwd())
    # logger.log(msg="The content of the cwd is: ", os.listdir())
    # logger.log(msg=f"The contents of the directory {DOCKER_DB_PATH}, the directory inside the container, is: ", os.listdir("/var/task/mnt/efs"))
    ##################################################################################
    logger.log(msg=f"Contents of the directory provided to the meili engine, {DB_PATH}, is: {os.listdir(DB_PATH)}")
    for ext in os.listdir(DB_PATH):
        logger.log(msg=
            f"The contents of the directory extension with {os.path.join(DB_PATH, ext)}, is: {os.listdir(os.path.join(DB_PATH, ext))}"
        )
    return {
        "statusCode": 200,
        "body": json.dumps("Completed indexing and added data to EFS"),
    }
