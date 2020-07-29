tableextension 82003 "AVU Contact" extends "Contact"
{
    fields
    {
        field(82000; "AVU Title"; Text[30])
        {
            Caption = 'Title';
            DataClassification = CustomerContent;
        }
        field(82001; "AVU Person ID"; Text[30])
        {
            Caption = 'Person ID';
            DataClassification = CustomerContent;
        }
        field(82002; "AVU Contact Type"; Text[30])
        {
            Caption = 'Contact Type';
            DataClassification = CustomerContent;
        }
        field(82003; "AVU Special Supplier"; Boolean)
        {
            Caption = 'Special Supplier';
            DataClassification = CustomerContent;
        }
    }
}