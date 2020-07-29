pageextension 82000 "AVU Payment Terms" extends "Payment Terms"
{
    layout
    {
        addafter("Due Date Calculation")
        {
            field("AVU Due Date Ship. Calculation"; "AVU Due Date Ship. Calculation")
            {
                ApplicationArea = All;
            }
        }
    }
}