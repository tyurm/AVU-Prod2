pageextension 82027 "AVU Item List" extends "Item List"
{
    layout
    {
        addafter("No.")
        {
            field("AVU No. 2"; "No. 2")
            {
                ApplicationArea = All;
            }
        }
        addlast(Control1)
        {
            field("AVU Name"; "AVU Name")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Producer No."; "AVU Producer No.")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Producer Name"; "AVU Producer Name")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Country of Origin Code"; "AVU Country of Origin Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Region"; "AVU Region Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Vintage"; "AVU Vintage Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Color Code"; "AVU Color Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Volume"; "AVU Volume Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Alcohol"; "AVU Alcohol Percent Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Classification"; "AVU Classification Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}