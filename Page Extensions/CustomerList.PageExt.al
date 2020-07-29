pageextension 82004 "AVU Customer List" extends "Customer List"
{
    actions
    {
        addlast(processing)
        {
            action("AVU Create Customer")
            {
                ApplicationArea = All;
                Caption = 'Create From Contact';
                Image = NewCustomer;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create new Customer from existing Contact.';
                trigger OnAction()
                var
                    Contact: Record Contact;
                    ContactMgmt: Codeunit "AVU Contact Management";
                begin
                    Contact.SetRange(Type, Contact.Type::Company);
                    if Page.RunModal(0, Contact) <> Action::LookupOK then
                        exit;
                    ContactMgmt.CreateCustomerFromContact(Contact);
                end;
            }
        }
    }
}