#!/usr/bin/env sh

set -x

echo "Please login to gcloud (required browser)"
gcloud auth login

if [ -z "${GOOGLE_BILLING_ACCOUNT_ID}" ]; then
  echo "Please set \$GOOGLE_BILLING_ACCOUNT_ID"
  exit 1
fi

if [ -z "${PREFIX}" ]; then
  echo "Please set \$PREFIX"
  exit 1
fi

export __TF_TERRAFORM_PROJECT="${PREFIX}-terraform"
export __TF_CURRENT_PROJECT="${PREFIX}-thee"
export __TF_CREDS="infrastructure/${PREFIX}-terraform.json"

gcloud projects create "${__TF_TERRAFORM_PROJECT}" \
  --set-as-default

gcloud beta billing projects link "${__TF_TERRAFORM_PROJECT}" \
  --billing-account="${GOOGLE_BILLING_ACCOUNT_ID}"

gcloud iam service-accounts create terraform \
  --project="${__TF_TERRAFORM_PROJECT}" \
  --display-name "Terraform"

gcloud iam service-accounts keys create "${__TF_CREDS}" \
  --project="${__TF_TERRAFORM_PROJECT}" \
  --iam-account="terraform@${__TF_TERRAFORM_PROJECT}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "${__TF_TERRAFORM_PROJECT}" \
  --project="${__TF_TERRAFORM_PROJECT}" \
  --member "serviceAccount:terraform@${__TF_TERRAFORM_PROJECT}.iam.gserviceaccount.com" \
  --role roles/viewer

gcloud projects add-iam-policy-binding "${__TF_TERRAFORM_PROJECT}" \
  --project="${__TF_TERRAFORM_PROJECT}" \
  --member "serviceAccount:terraform@${__TF_TERRAFORM_PROJECT}.iam.gserviceaccount.com" \
  --role roles/storage.admin

gcloud projects create "${__TF_CURRENT_PROJECT}"

gcloud beta billing projects link "${__TF_CURRENT_PROJECT}" \
  --billing-account="${GOOGLE_BILLING_ACCOUNT_ID}"

gcloud projects add-iam-policy-binding "${__TF_CURRENT_PROJECT}" \
  --project="${__TF_CURRENT_PROJECT}" \
  --member "serviceAccount:terraform@${__TF_TERRAFORM_PROJECT}.iam.gserviceaccount.com" \
  --role roles/owner

gsutil mb -p "${__TF_TERRAFORM_PROJECT}" "gs://${__TF_TERRAFORM_PROJECT}-tfstate"

cat > infrastructure/backend.tf << EOF
terraform {
 backend "gcs" {
   bucket  = "${__TF_TERRAFORM_PROJECT}-tfstate"
   prefix  = ""
 }
}
EOF
