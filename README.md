# **End-to-end lightning search** 

## Architecture overview:
<br>

Lambda function

Elastic Container Service

Elastic File System  




## Repo Structure
`app/` <br>
Containerised search engine
<br>
Containnerised indexing engine
<br>
`iac/`<br>
Infrastructure as code using terraform as the infrastructure as code tool and AWS as the Amazon web provider

## Workflow order
1) Initialise backend for terraform store (AWS) s3) via the shell script
`./utils/create-s3-tf-backend-bucket.sh`
2) Let terraform connect to the s3 backend:
`cd iac && terraform init`
3) Let terraform produce a plan for the infrastructure
`terraform plan`
4) Apply the iac plan with:
`terraform apply`
5) Clean up terraform's infra:
`terraform destroy`
6) Clean up state store for terraform:
`./utils/delete-s3-tf-backend-bucket.sh`


## Workload to do:
<br>
- The github action plan for the building on the indexer container needs to be created
<br>
- The search engine container needs to be configured to have access to the EFS (network file system service of AWS)



## Indexer
Indexer image: 
run from root dir
<br>
(_dockerfile contains layers necessary for non-standard python imports to be importable at runtime_)
<br>
__There is definitely as less convoluted way to run this so please let me know how__
<br>
`docker build ./ -f ./dockerfile.lambdaIndexer -t lambda-indexer:latest`
<br>
`docker run lambda-indexer:latest`
<br>
_from another terminal_
<br>
`docker exec -it $(docker ps --format "{{.Names}}") /bin/bash`
this gets you inside the container 
<br>
`python` 
<br>
`from indexer import hanlder`
`hander("","")`
<br>
_This will trigger the indexer_
__NOTE__:
<br>
Indexing is being artifically-slowed down; note this slow really, pre the indexer.py
<br>
once finished running
<br>
`exit()`
<br>
`cd mnt/efs && ls`
<br>
here are all the indexer files required. 
<br>
From outside docker container run:
<br>
This action below should not have to be taken, and instead be redundant via the fact the efs is mounted 
<br>
`docker cp $(docker ps --format "{{.Names}}"):/var/task/mnt/efs ./mnt/`
<br>
This copies the files from within the container to your local dir tree 

# Serving Search Engine
Once the indexing files have been generated, build the search-engine serving image

`docker build ./ -f ./dockerfile.searchEngine -t search-engine:latest`
<br>
initialise the engine

`docker run -p 10000:7700 search-engine:latest`

look at the command line output and see where the server listen. Change the port number to the one above
I.e. visit the webpage:
__http://0.0.0.0:10000__
enter the API key, you can find it in the dockerfile (MEILI_MASTER_KEY=_CBDdMT1hiwGuiTG4mWaXA), and in the command line too.
You'll be asked to enter this when you go to visit the webpage. 



<br>
