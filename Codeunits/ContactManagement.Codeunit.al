codeunit 82001 "AVU Contact Management"
{
    procedure CreateVendorFromContact(Contact: Record Contact);
    var
        Vendor: Record Vendor;
        ContBusRel: Record "Contact Business Relation";
    begin
        Contact.TestField("Company No.");
        if Contact."Company No." <> Contact."No." then
            Contact.Get(Contact."Company No.");

        if Vendor.Get(Contact."No.") then
            exit;

        if not ContBusRel.FindByContact(ContBusRel."Link to Table"::Vendor, Contact."No.") then
            ContBusRel.CreateRelation(Contact."No.", Contact."No.", ContBusRel."Link to Table"::Vendor);

        Vendor.Init();
        Vendor."No." := Contact."No.";
        Vendor.Name := Contact.Name;
        Vendor.Address := Contact.Address;
        Vendor."Address 2" := Contact."Address 2";
        Vendor.City := Contact.City;
        Vendor."Post Code" := Contact."Post Code";
        Vendor.Validate("Country/Region Code", Contact."Country/Region Code");
        Vendor.Validate("Purchaser Code", Contact."Salesperson Code");
        Vendor."Language Code" := Contact."Language Code";
        Vendor."VAT Registration No." := Contact."VAT Registration No.";
        Vendor.Validate("Gen. Bus. Posting Group", 'NAZIONALE');
        Vendor.Validate("Primary Contact No.", Vendor."No.");
        Vendor.SetInsertFromContact(true);
        Vendor.Insert(true);
    end;

    procedure CreateCustomerFromContact(Contact: Record Contact);
    var
        Customer: Record Customer;
        ContBusRel: Record "Contact Business Relation";
    begin
        Contact.TestField("Company No.");
        if Contact."Company No." <> Contact."No." then
            Contact.Get(Contact."Company No.");

        if Customer.Get(Contact."No.") then
            exit;

        if not ContBusRel.FindByContact(ContBusRel."Link to Table"::Customer, Contact."No.") then
            ContBusRel.CreateRelation(Contact."No.", Contact."No.", ContBusRel."Link to Table"::Customer);

        Customer.Init();
        Customer."No." := Contact."No.";
        Customer.Name := Contact.Name;
        Customer.Address := Contact.Address;
        Customer."Address 2" := Contact."Address 2";
        Customer.City := Contact.City;
        Customer."Post Code" := Contact."Post Code";
        Customer.Validate("Country/Region Code", Contact."Country/Region Code");
        Customer.Validate("Salesperson Code", Contact."Salesperson Code");
        Customer."Language Code" := Contact."Language Code";
        Customer."VAT Registration No." := Contact."VAT Registration No.";
        Customer.Validate("Customer Posting Group", 'NAZIONALE');
        Customer.Validate("Primary Contact No.", Customer."No.");
        Customer.SetInsertFromContact(true);
        Customer.Insert(true);
    end;
}