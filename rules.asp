ASP_PROGRAM = r"""% Neuro-symbolic counterfactual search for the Adult Income dataset.
%
% This ASP file contains the symbolic knowledge base:
% - which features are editable or fixed
% - which changes are legal
% - which values are realistic
% - how to minimize the number of changed features

% ---------------------------------------------------------------------
% Editable and fixed features
% ---------------------------------------------------------------------

editable(hours).
editable(education).
editable(occupation).

fixed(age).
fixed(sex).

% ---------------------------------------------------------------------
% Legal value domains
% ---------------------------------------------------------------------

% Weekly hours can only move in small steps.
delta_hours(-10; -5; 0; 5; 10).

% Occupation changes are also local transitions.
can_change_occupation("Adm-clerical", "Exec-managerial").
can_change_occupation("Exec-managerial", "Adm-clerical").
can_change_occupation("Adm-clerical", "Sales").
can_change_occupation("Sales", "Adm-clerical").
can_change_occupation("Sales", "Tech-support").
can_change_occupation("Tech-support", "Sales").
can_change_occupation("Tech-support", "Prof-specialty").
can_change_occupation("Prof-specialty", "Tech-support").
can_change_occupation("Prof-specialty", "Exec-managerial").
can_change_occupation("Exec-managerial", "Prof-specialty").
can_change_occupation("Craft-repair", "Machine-op-inspct").
can_change_occupation("Machine-op-inspct", "Craft-repair").
can_change_occupation("Craft-repair", "Transport-moving").
can_change_occupation("Transport-moving", "Craft-repair").
can_change_occupation("Craft-repair", "Farming-fishing").
can_change_occupation("Farming-fishing", "Craft-repair").
can_change_occupation("Handlers-cleaners", "Other-service").
can_change_occupation("Other-service", "Handlers-cleaners").
can_change_occupation("Other-service", "Priv-house-serv").
can_change_occupation("Priv-house-serv", "Other-service").
can_change_occupation("Protective-serv", "Armed-Forces").
can_change_occupation("Armed-Forces", "Protective-serv").

% Education changes are local transitions only.
% This prevents unrealistic jumps such as Bachelors -> Doctorate.
can_change_education("Preschool", "1st-4th").
can_change_education("1st-4th", "Preschool").
can_change_education("1st-4th", "5th-6th").
can_change_education("5th-6th", "1st-4th").
can_change_education("5th-6th", "7th-8th").
can_change_education("7th-8th", "5th-6th").
can_change_education("7th-8th", "9th").
can_change_education("9th", "7th-8th").
can_change_education("9th", "10th").
can_change_education("10th", "9th").
can_change_education("10th", "11th").
can_change_education("11th", "10th").
can_change_education("11th", "12th").
can_change_education("12th", "11th").
can_change_education("12th", "HS-grad").
can_change_education("HS-grad", "12th").
can_change_education("HS-grad", "Some-college").
can_change_education("Some-college", "HS-grad").
can_change_education("Some-college", "Assoc-voc").
can_change_education("Assoc-voc", "Some-college").
can_change_education("Assoc-voc", "Assoc-acdm").
can_change_education("Assoc-acdm", "Assoc-voc").
can_change_education("Assoc-acdm", "Bachelors").
can_change_education("Bachelors", "Assoc-acdm").
can_change_education("Bachelors", "Masters").
can_change_education("Masters", "Bachelors").
can_change_education("Masters", "Prof-school").
can_change_education("Prof-school", "Masters").
can_change_education("Prof-school", "Doctorate").
can_change_education("Doctorate", "Prof-school").

% ---------------------------------------------------------------------
% Candidate generation
% ---------------------------------------------------------------------

1 { choose_hours(Delta) : delta_hours(Delta) } 1.
new_value(hours, NewHours) :-
    old_value(hours, Hours),
    choose_hours(Delta),
    NewHours = Hours + Delta.

new_value(education, Education) :-
    old_value(education, Education),
    not changed_education.

0 { changed_education } 1.
1 { new_value(education, NewEducation) : can_change_education(Education, NewEducation) } 1 :-
    old_value(education, Education),
    editable(education),
    changed_education.

new_value(occupation, Occupation) :-
    old_value(occupation, Occupation),
    not changed_occupation.

0 { changed_occupation } 1.
1 { new_value(occupation, NewOccupation) : can_change_occupation(Occupation, NewOccupation) } 1 :-
    old_value(occupation, Occupation),
    editable(occupation),
    changed_occupation.

new_value(Feature, Value) :-
    old_value(Feature, Value),
    fixed(Feature).

% ---------------------------------------------------------------------
% Validity constraints
% ---------------------------------------------------------------------

% Fixed features cannot change.
:- fixed(Feature), old_value(Feature, Old), new_value(Feature, New), Old != New.

% Hours must stay realistic.
:- new_value(hours, Hours), Hours < 1.
:- new_value(hours, Hours), Hours > 80.

% Changed occupations must follow the allowed transition graph.
:- old_value(occupation, Old), new_value(occupation, New), Old != New, not can_change_occupation(Old, New).

% ---------------------------------------------------------------------
% Change counting and minimality
% ---------------------------------------------------------------------

changed(hours) :-
    old_value(hours, Old),
    new_value(hours, New),
    Old != New.

changed(education) :-
    old_value(education, Old),
    new_value(education, New),
    Old != New.

changed(occupation) :-
    old_value(occupation, Old),
    new_value(occupation, New),
    Old != New.

% Python iterates over budgets 1, 2, 3.
% to inspect and still keeps ASP responsible for valid candidate generation.
:- change_budget(Budget), Budget != #count { Feature : changed(Feature) }.

#minimize { 1, Feature : changed(Feature) }.

#show new_value/2.
#show changed/1.
"""