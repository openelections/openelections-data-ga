import json


def flatten_precinct_level_election_data(data):

    json_data = json.loads(data)

    # Extract relevant data from the JSON
    election_name = json_data.get('election_name')
    election_date = json_data.get('election_date')

    # Initialize an empty list to store the flattened data
    flattened_data = []

    # Iterate through each county/precinct results
    for result in json_data.get('local_results'):
        for ballot_item in result.get('ballot_items'):
            for ballot_option in ballot_item.get('ballot_options'):
                for precinct_result in ballot_option.get('precinct_results'):
                    for precinct_vote in precinct_result.get('precinct_votes'):
                        flattened_data.append(
                            {
                                'election_name': election_name,
                                'election_date': election_date,
                                'county': result.get('county'),
                                'number_precincts': len(ballot_option.get('precinct_results')),
                                'office': ballot_item.get('office'),
                                'candidate': ballot_option.get('candidate'),
                                'party': ballot_option.get('party'),
                                'precinct_id': precinct_result.get('precinct_id'),
                                'precinct_name': precinct_result.get('precinct_name'),
                                'precinct_reporting_status': precinct_result.get('reporting_status'),
                                'total_votes': precinct_result.get('total_votes'),
                                'vote_type': precinct_vote.get('vote_type'),
                                'votes': precinct_vote.get('votes')
                            }
                        )

    return flattened_data


def flatten_county_level_election_data(data):

    json_data = json.loads(data)

    # Extract relevant data from the JSON
    election_name = json_data.get('election_name')
    election_date = json_data.get('election_date')

    # Initialize an empty list to store the flattened data
    flattened_data = []

    # Iterate through each county's results
    for result in json_data.get('local_results'):
        for ballot_item in result.get('ballot_items'):
            for ballot_option in ballot_item.get('ballot_options'):
                for county_vote in ballot_option.get('county_votes'):
                    flattened_data.append(
                        {
                            'election_name': election_name,
                            'election_date': election_date,
                            'county': result.get('county'),
                            'office': ballot_item.get('office'),
                            'candidate': ballot_option.get('candidate'),
                            'party': ballot_option.get('party'),
                            'vote_type': county_vote.get('vote_type'),
                            'votes': county_vote.get('votes'),
                            'total_votes': ballot_option.get('total_votes')
                        }
                    )

    return flattened_data
