pageextension 82021 "AVU Posted Purchase Invoices" extends "Posted Purchase Invoices"
{
    layout
    {
        addafter("Amount Including VAT")
        {
            field("AVU Invoice Discount Amount"; "Invoice Discount Amount")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
    }
}
