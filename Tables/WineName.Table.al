table 82006 "AVU Wine Name"
{
    Caption = 'Wine Name';
    LookupPageId = "AVU Wine Names";
    DrillDownPageId = "AVU Wine Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Text[80])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

}
