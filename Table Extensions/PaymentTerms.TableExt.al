tableextension 82001 "AVU Payment Terms" extends "Payment Terms"
{
    fields
    {
        field(82000; "AVU Due Date Ship. Calculation"; DateFormula)
        {
            Caption = 'Due Date Shipment Calculation';
            DataClassification = CustomerContent;
        }
    }
}