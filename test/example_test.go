package test

import (
	"fmt"
	"testing"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEc2InstanceProvisioning(t *testing.T) {
   t.Parallel()
  approvedRegions := []string{"ap-southeast-1"}
  awsRegion := aws.GetRandomRegion(t, approvedRegions, nil)
	expectedName := fmt.Sprintf("terratest-aws-example-%s", random.UniqueId())
	terraformOptions := &terraform.Options{
      // The path to where our Terraform code is located
      TerraformDir: "../src",

      // Variables to pass to our Terraform code using -var options
      Vars: map[string]interface{}{
         "instance_name": expectedName,
         "test_label": "yes",
				 "region":awsRegion,
      },

      // Environment variables to set when running Terraform
      EnvVars: map[string]string{
         "AWS_DEFAULT_REGION": awsRegion,
      },
   }
  // At the end of the test, run `terraform destroy`
  defer terraform.Destroy(t, terraformOptions)
  // Run `terraform init` and `terraform apply`
  terraform.InitAndApply(t, terraformOptions)
	actualInstanceId := []string{terraform.Output(t, terraformOptions, "instance_id")}

  // let's check that the instance is actually there by looking for it with it's tag:
  tagName := "Name"
  exptectedInstanceId := aws.GetEc2InstanceIdsByTag(t, awsRegion, tagName, expectedName)

  // check it's the instance just created
  assert.Equal(t, exptectedInstanceId, actualInstanceId)
}