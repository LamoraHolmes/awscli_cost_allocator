# AWSCLI cost allocator

I needed to get a costoverview in three different AWS accounts and format the data in an AWS Quicksight usable format.

Additionally, I wanted to run the script as cronjob inside an AWS ECS Container.

## Parts you have to change

- You have to change the account IDs in the .json files

- You have to edit the data in the config file and enter your ecs roles

- In the run.sh script you need to enter the path to your s3 bucket

- In start.sh you have to enter your s3 bucket aswell