def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end

def usage()
    puts "Usage: main2.rb"
    puts ""
    puts "    ruby main2.rb <project id>"
    puts ""
    puts "where <project id> is the id of the project you wish to"
    puts "import data for. Currently the data is read from"
    puts "data/ap2dataout.xlsx"
end
