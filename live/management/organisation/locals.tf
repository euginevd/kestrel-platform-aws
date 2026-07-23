locals {
  standard_tags = {
    DataClassification = "OFFICIAL"
    Owner              = "platform-team@kestrel.com.au"
    CostCentre         = "CC-PLATFORM"
    Application        = "landing-zone"
  }

  # The monitored distribution lists — never individuals, or an abuse
  # report or compromise warning fails silently the day someone changes
  # roles (Organisation step 6).
  alternate_contacts = {
    BILLING = {
      email = "aws-billing@kestrel.com.au"
      name  = "Kestrel Billing"
      phone = "+61-2-5550-0000"
      title = "Billing (DL)"
    }
    OPERATIONS = {
      email = "aws-operations@kestrel.com.au"
      name  = "Kestrel Operations"
      phone = "+61-2-5550-0001"
      title = "Operations (DL)"
    }
    SECURITY = {
      email = "aws-security@kestrel.com.au"
      name  = "Kestrel Security"
      phone = "+61-2-5550-0002"
      title = "Security (DL)"
    }
  }
}
