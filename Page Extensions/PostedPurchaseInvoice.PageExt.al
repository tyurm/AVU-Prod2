pageextension 82022 "AVU Posted Purchase Invoice" extends "Posted Purchase Invoice"
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
