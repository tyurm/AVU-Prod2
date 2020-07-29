pageextension 82006 "AVU Purchase Order List" extends "Purchase Order List"
{
    layout
    {
        modify("Vendor Authorization No.")
        {
            Visible = false;
        }
        modify("Location Code")
        {
            Visible = false;
        }
        modify("Assigned User ID")
        {
            Visible = false;
        }
        modify(Status)
        {
            Visible = false;
        }
        addafter("Amount Including VAT")
        {
            field("AVU Invoice Discount value"; "Invoice Discount value")
            {
                ApplicationArea = All;
            }
            field("AVU Currency Code"; "Currency Code")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
    }
}
