f1 = open("count_1w.txt","r")

newFileStr = ""

for line in f1.readlines():
    newFileStr += line.split('\t')[0]+'\n'

f2 = open("frequent_words.txt","w+")

f2.write(newFileStr)