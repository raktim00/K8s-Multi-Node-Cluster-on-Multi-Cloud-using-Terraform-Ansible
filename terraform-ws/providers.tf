provider "aws" {
  profile = "example"
  region = "ap-south-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
   project     = "exampleproject"
   region      = "asia-south1"
}