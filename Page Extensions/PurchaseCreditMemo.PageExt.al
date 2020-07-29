pageextension 82016 "AVU Purchase Credit Memo" extends "Purchase Credit Memo"
{
    layout
    {
        modify("Buy-from Contact")
        {
            Visible = false;
        }
        modify("Order Address Code")
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
            field("AVU Vendor Posting Group"; "Vendor Posting Group")
            {
                ApplicationArea = All;
            }
            field("AVU Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
    }
}
