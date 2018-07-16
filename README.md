# aws-purge-region
Removes all associated resources (instances, elastic ips, dedicated hosts, AMIs, VPCs, volumes, load balancers, etc.) from specific Amazon AWS region.

## Idea
The idea behind the script is to purge all resources in an Amazon AWS region.

## Pre requirements
1. You need to install *AWS Command Line Interface*. [More info here](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).
2. You will need to set AWS credentials for the CLI. [More info here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html#cli-using-examples).

## Usage
### Purge a single region
`./aws-purge-region --single <region_name>`
### Purge all regions
`./aws-purge-region --all`
### Special options
`--exclude <regions_separated_by_comma>`

## Examples
### To remove everything from US East (N. Virginia) a single region:
`./aws-purge-region --single us-east-1`

### To remove everything except US East (N. Virginia)
`./aws-purge-region --all --exclude us-east-1,us-west-1`

*NOTE*: Info about available regions can be found here https://docs.aws.amazon.com/general/latest/gr/rande.html.
