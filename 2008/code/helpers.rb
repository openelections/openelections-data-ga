def write_csv(data, fname)
	keys = data.flat_map(&:keys).uniq
	# puts keys
	CSV.open('../' + fname, "wb") do |csv|
	  csv << keys # adds the attributes name on the first line
	  data.each do |d|
	    csv << d.values_at(*keys)
	  end
	end
end

# Method to get county-level results for each state-level election
def get_detail(base_url, href, off, dist, party)
	elex_url = base_url + href
	elex_details = Nokogiri::HTML(open(elex_url))
	answer = []
	rows = elex_details.css('table')[-1].css('tr')

	names = rows[0].css('td')[3..-1].map(&:text).map{ |n| n.gsub("\t", ' ').gsub("\r", ' ').gsub("(", '').gsub(")", '').split(' ')}

	rows = rows[3..-1] # Skip the first three rows because there's nothing in it

	rows.each do |r|
	    tds = r.css('td').map(&:text).map{ |n| n.gsub("\t", ' ').gsub("\r", ' ').gsub("(", '').gsub(")", '').strip.gsub(",","")}

	    names.each_with_index do |n, i|
	    	temp = {"office"=> off,"candidate"=>n[0], "party" => party, "county" => tds[0].capitalize, "votes"=>tds[3+i].to_i, "district"=> dist}
	    	answer << temp
	    end
	end
	return answer
end