pageextension 82011 "AVU G/L Account Card" extends "G/L Account Card"
{
    layout
    {
        addafter("Name")
        {
            field("AVU Name 2"; "AVU Name 2")
            {
                ApplicationArea = All;
            }
        }
    }
}