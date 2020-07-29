pageextension 82007 "AVU Purchase Order" extends "Purchase Order"
{
    layout
    {
        modify("No. of Archived Versions")
        {
            Visible = false;
        }
        modify("Buy-from Contact")
        {
            Visible = false;
        }
        modify("Vendor Shipment No.")
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
        moveafter("Buy-from Contact No."; "Currency Code")
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
        addafter("Buy-from")
        {
            field("AVU Currency Factor"; "Currency Factor")
            {
                ApplicationArea = All;
            }
        }
        moveafter("AVU Currency Factor"; Status)
        addafter("Vendor Order No.")
        {
            field("AVU Posting No."; "Posting No.")
            {
                ApplicationArea = All;
                Visible = False;
            }
            field("AVU Receiving No."; "Receiving No.")
            {
                ApplicationArea = All;
                Visible = False;
            }

        }
    }
    actions
    {
    }
}
