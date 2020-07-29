table 82091 "AVU Table Error"
{
    DrillDownPageID = "AVU Table Errors";
    LookupPageID = "AVU Table Errors";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
            CalcFormula = Lookup (Field.FieldName WHERE(TableNo = FIELD("Table ID"), "No." = FIELD("Field No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Error; Text[250])
        {
            Caption = 'Error';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Entry No.") { }
    }
}

