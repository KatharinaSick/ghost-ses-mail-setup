#!/bin/sh

print_usage () {
  echo "requires jq and curl"
}

get_all_destinations() {
  destinations=$(cat $ghost_export_file | jq '.db[0].data.members[] | select(.subscribed == 1) | { "Destination": { "ToAddresses": [.email] }, "ReplacementTemplateData": ("{ \"unsubscribeUrl\": \"https://ksick.dev/unsubscribe/?uuid=" + .uuid + "\"}") }' | jq --slurp '.')
}

get_default_template_data() {
  title_key="title"
  url_key="url"
  content_key="html"
  
  post_data=$(curl -X GET "https://ksick.dev/ghost/api/v3/content/posts/?key=${ghost_api_key}&fields=${title_key},${url_key},${content_key}&limit=1")

  post_title=$(jq -r ".posts[0].${title_key}" <<< $post_data | tr '"' '\"')
  post_excerpt=$(echo $(jq -r ".posts[0].${content_key}" <<< $post_data) | awk -v FS="(<p>|</p>)" '{print $2}' | tr '"' '\"')
  post_url=$(jq -r ".posts[0].${url_key}" <<< $post_data | tr '"' '\"') 

  default_template_data=$(jq -nc \
    --arg title "$post_title" \
    --arg excerpt "$post_excerpt" \
    --arg url "$post_url" \
    '{postTitle: $title, postExcerpt: $excerpt, postUrl: $url}' \
  )
}

# check if input argument is given
if [[ $# -ne 2 ]] ; then
  print_usage
  exit
fi

# input arguments
ghost_api_key=$1
ghost_export_file=$2

# the destinations the mail should be sent to
destinations

# information about the newest blog post
default_template_data

# fetch all necessarey information
get_all_destinations
get_default_template_data

# generate a json containing information about the bulk email that will be sent out
bulk_mail_json=$(jq -nR \
  --arg source "ksick.dev <noreply@ksick.dev>" \
  --arg template "NewPostTemplate" \
  --arg config_set_name "NewPostConfig" \
  --argjson destinations "$destinations" \
  --arg default_template_data "$default_template_data" \
  '{Source: $source, Template: $template, ConfigurationSetName: $config_set_name, Destinations: $destinations, DefaultTemplateData: $default_template_data}' \
)

template_file="bulk_mail_template.json"

# write json to template file
echo "$bulk_mail_json" > $template_file

# send out the email via AWS SES
aws ses send-bulk-templated-email --cli-input-json file://$template_file

# delete template file
rm $template_file
