table 82090 "AVU Table"
{
    DrillDownPageID = "AVU Tables";
    LookupPageID = "AVU Tables";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(2; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            CalcFormula = Lookup (AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "No. of Records"; Integer)
        {
            Caption = 'No. of Records';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(4; "No. of Table Relation Errors"; Integer)
        {
            CalcFormula = Count ("AVU Table Error" where("Table ID" = field("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Delete Records"; Boolean)
        {
            Caption = 'Delete Records';
            DataClassification = CustomerContent;
        }
        field(6; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Table ID") { }
    }

    trigger OnInsert()
    begin
        "Company Name" := CopyStr(CompanyName(), 1, MaxStrLen("Company Name"));
    end;
}

