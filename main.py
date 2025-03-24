def extract_hyperlinks_txt_file():
    txt_file = open('hyperlink.html', 'r')
    read = txt_file.read()
    lines = read.split()

    links = ''
    for i in lines:
        if 'href="http' in i:
            links += i

    split_quote_m = links.split('"')

    f = open('links.txt', 'a')
    for i in split_quote_m:
        if 'http' in i:
            f.write(i)
            f.write('\n')

extract_hyperlinks_txt_file()