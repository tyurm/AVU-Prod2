pageextension 82010 "AVU G/L Account List" extends "G/L Account List"
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