pageextension 82025 "AVU Posted Purch. Credit Memo" extends "Posted Purchase Credit Memo"
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
        addafter("Document Date")
        {
            field("AVU Vendor Posting Group"; "Vendor Posting Group")
            {
                ApplicationArea = All;
            }
            field("AVU Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
            }
            field("AVU VAT Bus. Posting Group"; "VAT Bus. Posting Group")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
    }
}
