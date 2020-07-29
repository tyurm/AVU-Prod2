pageextension 82028 "AVU Item Card" extends "Item Card"
{
    layout
    {
        modify(Description)
        {
            Width = 100;
        }
        modify(GTIN)
        {
            Visible = false;
        }
        addafter("No.")
        {
            field("AVU No. 2"; "No. 2")
            {
                ApplicationArea = All;
            }
        }
        addafter(Item)
        {
            group(AVU)
            {
                field("AVU Name"; "AVU Name")
                {
                    ApplicationArea = All;
                }
                field("AVU Producer No."; "AVU Producer No.")
                {
                    ApplicationArea = All;
                }
                field("AVU Producer Name"; "AVU Producer Name")
                {
                    ApplicationArea = All;
                }
                field("AVU Country of Origin Code"; "AVU Country of Origin Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Region"; "AVU Region Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Vintage"; "AVU Vintage Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Color Code"; "AVU Color Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Volume"; "AVU Volume Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Alcohol"; "AVU Alcohol Percent Code")
                {
                    ApplicationArea = All;
                }
                field("AVU Classification"; "AVU Classification Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}