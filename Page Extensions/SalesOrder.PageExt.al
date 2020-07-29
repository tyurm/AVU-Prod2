pageextension 82030 "AVU Sales Order" extends "Sales Order"
{
    layout
    {
        modify("No. of Archived Versions")
        {
            Visible = false;
        }
        modify("Responsibility Center")
        {
            Visible = false;
        }
        modify("Assigned User ID")
        {
            Visible = false;
        }
        moveafter("Due Date"; "VAT Bus. Posting Group")
        addafter("Due Date")
        {
            field("AVU VAT Country/Region Code"; "VAT Country/Region Code")
            {
                ApplicationArea = All;
            }
            field("AVU Customer Posting Group"; "Customer Posting Group")
            {
                ApplicationArea = All;
            }
            field("AVU Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
            }
        }
        addafter("External Document No.")
        {
            field("Posting No."; "Posting No.")
            {
                ApplicationArea = All;
                Importance = Additional;
            }
        }
    }
    actions
    {
    }
}
