#!/usr/bin/env ruby

require 'json'
require 'date'

EU12 = ["Austria", "Belgium", "Finland", "France", "Germany", "Greece", "Ireland", "Italy", "Luxembourg", "Netherlands", "Portugal", "Spain"]
repl = {"Austria" => "Au", "Belgium" => "Be", "Finland" => "Fi", "France" => "Fr", "Germany" => "Ge", "Greece" => "Gr", "Ireland" => "Ir", "Italy" => "It", "Luxembourg" => "Lu", "Netherlands" => "Ne", "Portugal" => "Po", "Spain" => "Sp"}

firstdate = Date.strptime("01/01/2006", "%d/%m/%Y")

def med(vs)
    if vs.length.odd?
        (vs[vs.length/2] + vs[(vs.length/2)+1]).to_f/2
    else
        vs[vs.length/2]
    end
end

def aggbyfield(field, lines, splitter=/\t/)
    h = {}
    lines.each { |l|
        d = l.split(splitter)[field]
        if h.has_key?(d)
            h[d] << l
        else
            h[d] = [l]
        end
    }
    return h
end

def cv(s, round = true)
    if s.nil? or s.empty? then
        nil
    else
        sp = s.strip.gsub(/\"/, "")
        if sp.empty? or sp =~ /^:$/
            nil
        else
            num = sp.gsub(/\s+/, "").to_f
            if round
                (num * 100).round.to_f / 100
            else
                num
            end
        end
    end
end

data = {}

debt = {}

debtcsv = IO.readlines("debt.csv")[1..-1]
debth = aggbyfield(0, debtcsv)
debth.each { |d,lines|
    y = d[1..4].to_i
    (0..2).each { |md|
        m = (3 * d[-2..-2].to_i) - md
        datestr = m.to_s + "/" + y.to_s
        date = Date.strptime(datestr, "%m/%Y")
        debt[date] = {} unless debt.has_key?(date)
        lines.each { |l|
            country = EU12.find { |c| l.split(/\t/)[1] =~ Regexp.new(c) }
            debt[date][repl[country]] = cv(l.split(/\t/)[5])
        }
    }
}

deficit = {}
deficitcsv = IO.readlines("deficit.csv")[5..-1]

deforder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
deficitcsv.each { |l|
    d = l.split(/\t/)[0]
    y = d[1..4].to_i
    (0..2).each { |md|
        m = (3 * d[-2..-2].to_i) - md
        datestr = m.to_s + "/" + y.to_s
        date = Date.strptime(datestr, "%m/%Y")
        if date >= firstdate
            deficit[date] = {} unless deficit.has_key?(date)
            deforder.each_with_index { |i,j|
                deficit[date][repl[EU12[i]]] = cv(l.split(/\t/)[j+1])
            }
        end
    }
}

gdpgrowth = {}

gdpgcsv = IO.readlines("gdp-change.csv")[1..-1]
gdpgh = aggbyfield(0, gdpgcsv)
gdpgh.each { |d,lines|
    y = d[1..4].to_i
    (0..2).each { |md|
        m = (3 * d[-2..-2].to_i) - md
        datestr = m.to_s + "/" + y.to_s
        date = Date.strptime(datestr, "%m/%Y")
        gdpgrowth[date] = {} unless gdpgrowth.has_key?(date)
        lines.each { |l|
            country = EU12.find { |c| l.split(/\t/)[1] =~ Regexp.new(c) }
            gdpgrowth[date][repl[country]] = cv(l.split(/\t/)[5])
        }
    }
}

inflation = {}
inflationcsv = IO.readlines("inflation.csv")[5..-1]

iorder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
inflationcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        inflation[date] = {} unless inflation.has_key?(date)
        iorder.each_with_index { |i,j|
            inflation[date][repl[EU12[i]]] = cv(l.split(/,/)[j+1])
        }
    end
}

interest = {}
interestcsv = IO.readlines("interest.csv")[5..-1]

inorder = [0, 1, -1, 4, 11, 2, 3, 5, 6, 7, 8, -1, 9, 10, -1, -1]
interestcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        interest[date] = {} unless interest.has_key?(date)
        inorder.each_with_index { |i,j|
            interest[date][repl[EU12[i]]] = cv(l.split(/,/)[j+1]) unless i == -1
        }
    end
}

unemployment = {}
unemploymentcsv = IO.readlines("unemployment.csv")[5..-1]

uorder = [0, 1, 4, 11, 2, 3, 5, 6, 7, 8, 9, 10]
unemploymentcsv.each { |l|
    d = l.split(/,/)[0]
    datestr = d[4..-1] + "/" + d[0..3]
    date = Date.strptime(datestr, "%b/%Y")
    if date >= firstdate
        unemployment[date] = {} unless unemployment.has_key?(date)
        uorder.each_with_index { |i,j|
            unemployment[date][repl[EU12[i]]] = cv(l.split(/,/)[j+1])
        }
    end
}

investment = {}

investmentcsv = IO.readlines("gdp-investment-oecd.csv")[1..-1]
investmenth = aggbyfield(-3, investmentcsv, /,/)
investmenth.each { |d,lines|
    y = d[-5..-2].to_i
    (0..2).each { |md|
        m = (3 * d[2..2].to_i) - md
        datestr = m.to_s + "/" + y.to_s
        date = Date.strptime(datestr, "%m/%Y")
        investment[date] = {} unless investment.has_key?(date)
        gdp = {}
        inv = {}
        lines.each { |l|
            country = EU12.find { |c| l.split(/,/)[-4] =~ Regexp.new(c) }
            if l.split(/,/)[0] =~ /capital formation/
                inv[country] = cv(l.split(/,/)[-2])
            else
                gdp[country] = cv(l.split(/,/)[-2])
            end
        }
        EU12.each { |c|
            investment[date][repl[c]] = if inv[c].nil? or gdp[c].nil?
                                            nil
                                        else
                                            ((inv[c] / gdp[c]) * 10000).round.to_f / 100
                                        end
        }
    }
}
inv2011 = {"Au" => 22.742, "Be" => 19.806, "Fi" => 19.944, "Fr" => 21.213, "Ge" => 19.106, "Gr" => 12.382, "Ir" => 9.985, "It" => 19.942, "Lu" => 17.686, "Ne" => 19.393, "Po" => 17.587, "Sp" => 21.842}
(1..12).each { |m|
    datestr = m.to_s + "/2011"
    date = Date.strptime(datestr, "%m/%Y")
    if investment.has_key?(date)
        inv2011.each { |k,v|
            investment[date][k] = v unless investment[date].has_key?(k) and not investment[date][k].nil?
        }
    else
        investment[date] = {}
        inv2011.each { |k,v|
            investment[date][k] = v
        }
    end
}

edebt = {}

edebtcsv = IO.readlines("external-debt.csv")[1..-1]
pddates = ["2006Q1", "2006Q2", "2006Q3", "2006Q4", "2007Q1", "2007Q2", "2007Q3", "2007Q4", "2008Q1", "2008Q2", "2008Q3", "2008Q4", "2009Q1", "2009Q2", "2009Q3", "2009Q4", "2010Q1", "2010Q2", "2010Q3", "2010Q4", "2011Q1", "2011Q2", "2011Q3", "2011Q4"]
edebtcsv.each { |l|
    country = EU12.find { |c| l.split(/,/)[0] =~ Regexp.new(c) }
    pddates.each_with_index { |d,i|
        y = d[0..3].to_i
        (0..2).each { |md|
            m = (3 * d[-1..-1].to_i) - md
            datestr = m.to_s + "/" + y.to_s
            date = Date.strptime(datestr, "%m/%Y")
            edebt[date] = {} unless edebt.has_key?(date)
            edebt[date][repl[country]] = cv(l.split(/,/)[i+4])
        }
    }
}

gdpdollar = {}
gdpdollarcsv = IO.readlines("gdp-imf.csv")[1..-4]
gdates = ["2006", "2007", "2008", "2009", "2010", "2011"]
gdpdollarcsv.each { |l|
    splits = l.split(/\t/)
    if splits[1] =~ /Gross domestic product/
        country = EU12.find { |c| splits[0] =~ Regexp.new(c) }
        gdates.each_with_index { |d,i|
            date = Date.strptime(d, "%Y")
            gdpdollar[date] = {} unless gdpdollar.has_key?(date)
            gdpdollar[date][repl[country]] = cv(splits[i+4], false) * 1000000000
        }
    end
}
edebt.each { |d,cs|
    cs.each { |c,v|
        gdpdollardate = Date.strptime(d.year.to_s, "%Y")
        edebt[d][c] = if v.nil? or gdpdollar[gdpdollardate][c].nil?
                          nil
                      else
                          ((v / gdpdollar[gdpdollardate][c]) * 10000).round.to_f / 100
                      end
    }
}

#data["debt"] = debt
#data["deficit"] = deficit
#data["gdpgrowth"] = gdpgrowth
#data["inflation"] = inflation
#data["interest"] = interest
#data["unemployment"] = unemployment
#data["investment"] = investment
#data["externaldebt"] = edebt

# normalise and predict

interest.keys.sort.each { |k|
    tmp = {}
    next if not debt.has_key?(k) or debt[k].values.any? { |x| x.nil? }
    vs = debt[k].values.sort
    tmp["d"] = debt[k]
    tmp["d"]["mi"] = vs.min
    tmp["d"]["ma"] = vs.max
    tmp["d"]["me"] = med(vs)

    next if not deficit.has_key?(k) or deficit[k].values.any? { |x| x.nil? }
    vs = deficit[k].values.sort
    tmp["s"] = deficit[k]
    tmp["s"]["mi"] = vs.min
    tmp["s"]["ma"] = vs.max
    tmp["s"]["me"] = med(vs)

    next if not gdpgrowth.has_key?(k) or gdpgrowth[k].values.any? { |x| x.nil? }
    vs = gdpgrowth[k].values.sort
    tmp["g"] = gdpgrowth[k]
    tmp["g"]["mi"] = vs.min
    tmp["g"]["ma"] = vs.max
    tmp["g"]["me"] = med(vs)

    next if not inflation.has_key?(k) or inflation[k].values.any? { |x| x.nil? }
    vs = inflation[k].values.sort
    tmp["inf"] = inflation[k]
    tmp["inf"]["mi"] = vs.min
    tmp["inf"]["ma"] = vs.max
    tmp["inf"]["me"] = med(vs)

    next if not interest.has_key?(k) or interest[k].values.any? { |x| x.nil? }
    vs = interest[k].values.sort
    tmp["int"] = interest[k]
    tmp["int"]["mi"] = vs.min
    tmp["int"]["ma"] = vs.max
    tmp["int"]["me"] = med(vs)

    next if not unemployment.has_key?(k) or unemployment[k].values.any? { |x| x.nil? }
    vs = unemployment[k].values.sort
    tmp["u"] = unemployment[k]
    tmp["u"]["mi"] = vs.min
    tmp["u"]["ma"] = vs.max
    tmp["u"]["me"] = med(vs)

    next if not investment.has_key?(k) or investment[k].values.any? { |x| x.nil? }
    vs = investment[k].values.sort
    tmp["inv"] = investment[k]
    tmp["inv"]["mi"] = vs.min
    tmp["inv"]["ma"] = vs.max
    tmp["inv"]["me"] = med(vs)

    #next if not edebt.has_key?(k) or edebt[k].values.any? { |x| x.nil? }
    #ihashtmp = edebt[k].dup
    #ihashtmp.delete("L")
    #vs = ihashtmp.values.sort
    #tmp["edebt"] = edebt[k]
    #tmp["edebt"]["min"] = vs.min
    #tmp["edebt"]["max"] = vs.max
    #tmp["edebt"]["med"] = med(vs)

    data[k] = tmp
}

ndata = {}
data.keys.sort.collect { |d|
    ndata[d.year.to_s + "/" + d.month.to_s] = data[d]
}

ndata["2008/12"]["news"] = "EU leaders agree on a 200bn euro stimulus plan to help boost European growth following the global financial crisis."
ndata["2009/4"]["news"] = "EU orders France, Spain, Ireland and Greece to reduce their budget deficits."
ndata["2009/12"]["news"] = "Greece is burdened with debt amounting to 113% of GDP &mdash; nearly double the eurozone limit of 60%. Ratings agencies start to downgrade Greek bank and government debt."
ndata["2010/1"]["news"] = "An EU report condemns \"severe irregularities\" in Greek accounting procedures."
ndata["2010/2"]["news"] = "Greece unveils a series of austerity measures aimed at curbing the deficit."
ndata["2010/3"]["news"] = "The Eurozone and IMF agree a safety net of 22bn euro to help Greece."
ndata["2010/4"]["news"] = "The Eurozone countries agree to provide up to 30bn euro in emergency loans."
ndata["2010/5"]["news"] = "The Eurozone members and the IMF agree a 110bn euro bailout package to rescue Greece."
ndata["2010/11"]["news"] = "The EU and IMF agree to a bailout package to the Irish Republic totalling 85bn euro."
ndata["2011/2"]["news"] = "Eurozone finance ministers set up a permanent bailout fund, called the European Stability Mechanism, worth about 500bn euro."
ndata["2011/4"]["news"] = "Portugal admits it cannot deal with its finances itself and asks the EU for help."
ndata["2011/5"]["news"] = "The Eurozone and the IMF approve a 78bn euro bailout for Portugal."
ndata["2011/7"]["news"] = "The Eurozone agrees a comprehensive 109bn euro package designed to resolve the Greek crisis and prevent contagion among other European economies."
ndata["2011/8"]["news"] = "The European Central Bank says it will buy Italian and Spanish government bonds to try to bring down their borrowing costs."

jsondata = ndata.keys.sort { |a,b| Date.strptime(a, "%Y/%m") <=> Date.strptime(b, "%Y/%m") }.collect { |d|
    [d, ndata[d]]
    #puts d
}

puts jsondata.to_json
#puts JSON.pretty_generate(jsondata)
