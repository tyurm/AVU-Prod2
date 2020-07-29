pageextension 82017 "AVU Purch. Cr. Memo Subform" extends "Purch. Cr. Memo Subform"
{
    layout
    {
        modify("Tax Area Code")
        {
            Visible = false;
        }
        modify("Tax Group Code")
        {
            Visible = false;
        }
        modify("Shortcut Dimension 1 Code")
        {
            Visible = false;
        }
        modify("Shortcut Dimension 2 Code")
        {
            Visible = false;
        }
        modify(ShortcutDimCode3)
        {
            Visible = false;
        }
        addlast(Control1)
        {
            field("AVU Line No."; "Line No.")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Vat %"; "Vat %")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU VAT Bus. Posting Group"; "VAT Bus. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU VAT Prod. Posting Group"; "VAT Prod. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU VAT Identifier"; "VAT Identifier")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
    actions
    {
    }
}
