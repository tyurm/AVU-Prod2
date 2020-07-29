pageextension 82005 "AVU Vendor List" extends "Vendor List"
{
    actions
    {
        addlast(processing)
        {
            action("AVU Create Vendor")
            {
                ApplicationArea = All;
                Caption = 'Create From Contact';
                Image = NewCustomer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create new Vendor from existing Contact.';
                trigger OnAction()
                var
                    Contact: Record Contact;
                    ContactMgmt: Codeunit "AVU Contact Management";
                begin
                    Contact.SetRange(Type, Contact.Type::Company);
                    if Page.RunModal(0, Contact) <> Action::LookupOK then
                        exit;
                    ContactMgmt.CreateVendorFromContact(Contact);
                end;
            }
        }
    }
}