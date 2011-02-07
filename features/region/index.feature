Feature: Region main page
  In order to do pretty much everything on this website
  As a guest
  I want to do basic site navigation

  @javascript
  Scenario: Searching is automatically limited by region
    Given "Chicago" is a region with the name "chicago" and the id "1"
    And there is a location machine xref
    And I am on "Chicago"'s home page
    And I press "Search"
    Then I should not see the listing for "Test Location Name"

  @javascript
  Scenario: Search by location name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Location Name" from "by_location_id"
    And I press "Search"
    Then I should see the listing for "Test Location Name"

  @javascript
  Scenario: Search by machine name from select
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I select "Test Machine Name" from "by_machine_id"
    And I press "Search"
    Then I should see the listing for "Test Location Name"

  @javascript
  Scenario: Location detail shows the stuff that I want it to show
    Given there is a location machine xref
    And I am on "Portland"'s home page
    And I press "Search"
    Then I should see "Test Location Name"
    And I should see "123 Pine | Portland"
    And I should see "Add New Machine At This Location"
    And I should see "Show Machines At This Location"

  @javascript
  Scenario: Search by city
    Given there is a region with the name "portland" and the id "1"
    And the following locations exist:
      |name|city|region_id|
      |Cleo|Portland|1|
      |Sassy|Beaverton|1|
      |Zelda|Hillsboro|1|
      |Bawb|Hillsboro|1|
    And I am on "Portland"'s home page
    And I select "Beaverton" from "by_city"
    And I press "Search"
    Then I should see the listing for "Sassy"

  @javascript
  Scenario: Search by zone
    Given there is a region with the name "portland" and the id "1"
    And there is a zone with the name "Alberta" and the id "2" and the region_id "1"
    And the following locations exist:
      |name|zone_id|region_id|
      |Cleo|1|1|
      |Sassy|2|1|
    And I am on "Portland"'s home page
    And I select "Alberta" from "by_zone_id"
    And I press "Search"
    Then I should see the listing for "Sassy"
    And I should not see the listing for "Cleo"