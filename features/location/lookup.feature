Feature: Lookup Locations
  In order to check out some locations
  As a guest
  I want to lookup locations

  Scenario: Locations List
    Given a location exists with name: "Bar Cleo"
    And I am on the locations page
    Then I should see "Bar Cleo"

  Scenario: Pagination
    Given there are 51 locations
    And a location exists with name: "Bar Cleo"
    When I go to the locations page
    Then I should not see "Bar Cleo"

  Scenario: New location
    Given I am on the locations page
    When I follow "New Location"
    Then I should be on the new location page

  Scenario: Show location
    Given a location exists with name: "Bar Cleo"
    And I am on the locations page
    When I follow "Show"
    Then I should be on the location detail page for "Bar Cleo"

  Scenario: Edit location
    Given a location exists with name: "Bar Cleo"
    And I am on the locations page
    When I follow "Edit"
    Then I should be on the location edit page for "Bar Cleo"

  Scenario: Delete location
    Given a location exists with name: "Bar Cleo"
    And I am on the locations page
    When I follow "Destroy"
    Then I should be on the locations page
    And I should see "Location was successfully destroyed."

  Scenario: Search by name
    Given the following locations exist
      | name  |
      | Cleo  |
      | Sassy |
    When I go to the locations page
    And I fill in "Name" with "Cleo"
    And I press "Search"
    Then I should see "Cleo"
    And I should not see "Sassy"
