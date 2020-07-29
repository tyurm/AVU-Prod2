tableextension 82005 "AVU Item" extends "Item"
{
    fields
    {
        field(82000; "AVU Name"; Text[80])
        {
            Caption = 'Name';
            TableRelation = "AVU Wine Name";
            DataClassification = CustomerContent;
        }
        field(82001; "AVU Region"; Text[30])
        {
            Caption = 'Region';
            TableRelation = "AVU Region";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82002; "AVU Vintage"; Integer)
        {
            Caption = 'Vintage';
            TableRelation = "AVU Vintage";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82003; "AVU Color"; Option)
        {
            Caption = 'Color';
            OptionMembers = " ",Red,White,Sweet,Distilled,Sparkling,Rosé,Beer;
            OptionCaption = ' ,Red,White,Sweet,Distilled,Sparkling,Rosé,Beer';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82004; "AVU Alcohol"; Decimal)
        {
            Caption = 'Alcohol Percent Code';
            TableRelation = "AVU Alcohol Percent";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82005; "AVU Classification"; Text[30])
        {
            Caption = 'Classification Code';
            TableRelation = "AVU Classification";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82006; "AVU Volume"; Decimal)
        {
            Caption = 'Volume Code';
            TableRelation = "AVU Volume";
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Type changed';
        }
        field(82007; "AVU Country of Origin Code"; Code[10])
        {
            Caption = 'Country of Origin Code';
            TableRelation = "Country/Region";
        }
        field(82008; "AVU Region Code"; Code[20])
        {
            Caption = 'Region Code';
            TableRelation = "AVU Region";
            DataClassification = CustomerContent;
        }
        field(82009; "AVU Vintage Code"; Code[10])
        {
            Caption = 'Vintage Code';
            TableRelation = "AVU Vintage";
            DataClassification = CustomerContent;
        }
        field(82010; "AVU Alcohol Percent Code"; Code[10])
        {
            Caption = 'Alcohol Percent Code';
            TableRelation = "AVU Alcohol Percent";
            DataClassification = CustomerContent;
        }
        field(82011; "AVU Classification Code"; Code[20])
        {
            Caption = 'Classification Code';
            TableRelation = "AVU Classification";
            DataClassification = CustomerContent;
        }
        field(82012; "AVU Volume Code"; Code[10])
        {
            Caption = 'Volume Code';
            TableRelation = "AVU Volume";
            DataClassification = CustomerContent;
        }

        field(82013; "AVU Producer No."; Code[20])
        {
            Caption = 'Producer No.';
            TableRelation = "Contact";
            DataClassification = CustomerContent;
        }

        field(82014; "AVU Producer Name"; Text[100])
        {
            Caption = 'Producer Name';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup (Contact.Name where("No." = field("AVU Producer No.")));
        }
        field(82015; "AVU Color Code"; Code[20])
        {
            Caption = 'Color Code';
            TableRelation = "AVU Color";
            DataClassification = CustomerContent;
        }
    }
}