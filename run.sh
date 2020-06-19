#!/bin/bash

## Extract the Cost for all Accounts ##

firstday=$(date --date="$(date +'%Y-%m-01')" +%Y-%m-%d)
lastday=$(date --date="$(date +'%Y-%m-01') + 1 month" +%Y-%m-%d)

aws ce get-cost-and-usage --time-period Start=$firstday,End=$lastday --granularity MONTHLY --metrics "UnblendedCost" --group-by Type=DIMENSION,Key=SERVICE --filter file://dev_costs.json > dev_cost --profile dev
aws ce get-cost-and-usage --time-period Start=$firstday,End=$lastday --granularity MONTHLY --metrics "UnblendedCost" --group-by Type=DIMENSION,Key=SERVICE --filter file://qa_costs.json  > qa_cost --profile qa
aws ce get-cost-and-usage --time-period Start=$firstday,End=$lastday --granularity MONTHLY --metrics "UnblendedCost" --group-by Type=DIMENSION,Key=SERVICE --filter file://prod_costs.json  > prod_cost

sleep 2

## start to edit the output to change the format to use with Quicksight ##

timestamp=$(date +%b-%Y)

counter=0

while (( $counter < 3  ))

  do
    number=0

    if [ $counter = 0 ]; then
      stage="Dev"
      keys=$(grep -o -i keys dev_cost | wc -l)
      file="dev_cost"
    elif [ $counter = 1 ]; then
      stage="QA"
      keys=$(grep -o -i keys qa_cost | wc -l)
      file="qa_cost"
    else
      keys=$(grep -o -i keys prod_cost | wc -l)
      stage="Prod"
      file="prod_cost"
    fi

    while (( $number < $keys ))

      do
        cat $file | jq '.ResultsByTime[0].Groups['$number'].Keys, .ResultsByTime[0].Groups['$number'].Metrics.UnblendedCost.Amount, .ResultsByTime[0].Groups['$number'].Metrics.UnblendedCost.Unit' >> unformatedData ## Writes Service, Costs and Currency to the file

        number=$(( number+1 ))

      done

    cat unformatedData | sed 'y/[]/{}/' | sed 's/[}]//g' | sed '/{/ s/^/}\n/' | sed '/^$/d' | awk '{$1=$1};1' > temp  ## Replace [] with {}, removes empty lines and spaces

    sed -i '/}/ s/$/,/' temp ## append a , to every line with a closed bracket }

    sed -i '/"/ s/$/,/' temp  ## Add an comma to every line with a paragraph symbol
    sed -i 's/"USD"/"Currency":"USD"/g' temp  ## Adds Currency in front of USD
    sed -i -E '/\.|0/ s/^/"Costs":/' temp ## On every line with a 0 or a . we add Costs
    sed -i '/[.:{}]/! s/^/"Service":/' temp  ## Every line without a . : { } we add Service to it
    sed -i '/Costs/a "Date":"'$timestamp'",' temp ## Add the key for timestamp after every line with currency in it and chose as value the current month and year
    sed -i '/Costs/a "Stage":"'$stage'",' temp ## Add the key for stage after every line with currency in it and chose as value the right stage
    sed -i '1d' temp

    echo "}" >> temp #add a closing bracket at the end of the file

    echo "]" >> temp

    sed -i '1 i\[' temp #Adds a [ at the start of the file

    sed -i 's/"USD",/"USD"/g' temp ## remove , after USD

    cat temp >> costoverview

    rm  temp unformatedData

    counter=$(( counter+1 ))

done

aws s3 cp s3://your-s3-bucket/your-file-name

cat costoverview >> Costs

aws s3 cp Costs s3://your-s3-bucket/your-file-name

rm dev_cost qa_cost prod_cost Costs