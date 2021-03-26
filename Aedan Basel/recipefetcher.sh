#!/usr/bin/bash
echo > output.txt
# loop through menu and find urls for recipes, store them in a temp text file
cat $1 | while read line; do
  searchquery=${line// /+}
  curl "https://www.allrecipes.com/search/results/?search=$searchquery" > resultspage.txt
  cutresults=$(cat resultspage.txt | sed -n '/card__facetedSearchResult/,$p' | tail -n+7 | sed -n '/title="/q;p')
  noprefix=${cutresults/#*href=\"/}
  url=${noprefix/%\"/}
  echo $url >> urls.txt
done
rm resultspage.txt
#loop through urls and compile recipes into document
cat 'urls.txt' | while read line; do
  curl $line > recipe.txt
  cutrecipe=$(cat recipe.txt | sed -n '/mainEntityOfPage/,$p' | tail -n+2 | sed -n '/"review":/q;p')
  recipename=$(sed -n '/"image":/q;p' <<< $cutrecipe)
  recipename=${recipename/#*\"name\"\: \"/}
  recipename=${recipename/%\"\,/}
  echo $recipename >> output.txt
  echo >> output.txt
  echo 'Ingredients' >> output.txt
  ingredients=$(sed -n '/recipeIngredient/,$p' <<< $cutrecipe | tail -n+2 | sed -n '/recipeInstructions/q;p' | head -n-1)
  ingredients=${ingredients//\"/}
  echo $ingredients >> output.txt
  echo >> output.txt
  echo 'Instructions' >> output.txt
  instructions=$(sed -n '/recipeInstructions/,$p' <<< $cutrecipe | tail -n+4 | sed -n '/recipeCategory/q;p')
  # handle multiple steps from the json-formatted site code
  grep 'text' <<< $instructions | while read -r line; do
    instructions=${line/#*text\"\: \"/}
    instructions=${instructions//\\n\"/}
    echo $instructions >> output.txt
  done
  echo >> output.txt
  servings=$(grep 'recipeYield' <<< $cutrecipe)
  servings=${servings/#*recipeYield\"\: \"/}
  servings=${servings/%\"\,/}
  echo "Servings: $servings" >> output.txt
  echo >> output.txt
  echo >> output.txt
  echo >> output.txt
done
rm recipe.txt
rm urls.txt
