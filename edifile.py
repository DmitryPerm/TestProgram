#-*- coding: utf-8 -*-
import os
import shutil
import datetime
import tarfile
import zipfile
from sys import platform
import datetime
#from datetime import timedelta, datetime

def modification_date(filename):
    t = os.path.getmtime(filename)
    return datetime.datetime.fromtimestamp(t)

def exists(path):
    try:
        os.stat(path)
    except OSError:
        return False
    return True

Day = datetime.date.today().weekday()
if platform == "win32":
    double_slash = '\\'
    all_dirs = [r'C:\ns2000\Folder1', r'C:\ns2000\Folder2']
    dop_dirs = r'C:\ns2000\Folder3'
    Arc = 'zip'
elif platform == "linux" or platform == "linux2":
    double_slash = '//'
    if Day == 0 or Day == 4:
        all_dirs = [r'/usr/ns2000/edi/Copy.in',r'/usr/ns2000/edi/Copy.out']
        dop_dirs = r'/usr/ns2000/edi/Inbox'
    elif Day == 1 or Day == 5:
        all_dirs = [r'/usr/ns2000/edi-tensor/Copy.in',r'/usr/ns2000/edi-tensor/Copy.out']
        dop_dirs = r'/usr/ns2000/edi-tensor/Inbox'
    elif Day == 2 or Day == 6:
        all_dirs = [r'/usr/ns2000/edi-soft/Copy.in',r'/usr/ns2000/edi-soft/Copy.out']
        dop_dirs = r'/usr/ns2000/edi-soft/Inbox'
    else:
        all_dirs = [r'/usr/ns2000/edi-exite/Copy.in',r'/usr/ns2000/edi-exite/Copy.out']
        dop_dirs = r'/usr/ns2000/edi-exite/Inbox'
    Arc = 'tar'
File_name = ''
New_folder = ''
i = 0
leng_dirs = len(all_dirs)
now = datetime.datetime.now()
Year_today = now.year
YearVar = 0
Today_time = datetime.date.today()
Today_time_format = Today_time.strftime("%Y%m%d")
str_file = ''
word = 'invoice number'
word_2 = 'originOrder'

os.chdir(dop_dirs)
pos_2 = 0
week = datetime.timedelta(7)
need_data = now - week
dop_files = os.listdir(dop_dirs)
Filter_files = filter(lambda y: y.endswith('xml'), dop_files)
counter = len(Filter_files)
while counter > 0:
    if not Filter_files:
        break
    dop_filename = Filter_files[pos_2]
    sh_name = os.path.splitext(dop_filename)[0]
    temp_2 = sh_name.find('_')
    sh_name = sh_name[:temp_2]
    if sh_name == 'ORDRSP':
        dop_time = modification_date(dop_filename)
        dop_names = all_dirs[0]+double_slash+dop_filename
        if not os.path.exists(dop_names):
            if dop_time <= need_data:
                shutil.move(dop_filename,all_dirs[0])
        else:
            os.remove(dop_filename)
    counter -= 1
    pos_2 += 1

while i < leng_dirs:
    os.chdir(all_dirs[i])
    all_names = []
    pos = 0
    files = os.listdir(all_dirs[i])
    F_files = filter(lambda x: x.endswith('.xml'), files)
    F_files = sorted(F_files, key=os.path.getmtime)
    num = len(F_files) 
    while num > 0:
        os.chdir(all_dirs[i])
        if not F_files:
            break
        File_name = F_files[pos]
        Short_name = os.path.splitext(File_name)[0]
        temp = Short_name.find('_')
        Short_name = Short_name[:temp]
        Time = modification_date(File_name)
        Names = Time.strftime("%Y%m%d")
        YearVar = Time.strftime("%Y")      
        if not Names == Today_time_format:
            if Short_name == "INVOIC":
                with open(File_name,'r') as file:
                    for line in file:
                        if word in line:
                            line = Names + ' ' + line.strip() 
                            save = open(Short_name+'.txt','a')
                            save.write(line)
                            save.close()
                        if word_2 in line: 
                            save = open(Short_name+'.txt','a')
                            line = ' ' + line.strip() + ' ' + File_name
                            save.write(line + '\n')
                            save.close()
            if not str(YearVar) == str(Year_today):
                New_path_year = all_dirs[i]+double_slash+YearVar
                if not os.path.exists(New_path_year):
                    os.makedirs(New_path_year)
                if not os.path.exists(New_path_year+double_slash+Short_name):
                    os.makedirs(New_path_year+double_slash+Short_name)
                if exists(New_path_year):
                    if not os.path.exists(New_path_year+double_slash+Short_name+double_slash+File_name):
                        shutil.move(File_name,New_path_year+double_slash+Short_name)
                    else:
                        os.remove(File_name)
            else:
                New_path = all_dirs[i]+double_slash+Names
                if not os.path.exists(New_path):
                    os.makedirs(New_path)
                New_path_sh = New_path+double_slash+Short_name
                if not os.path.exists(New_path_sh):
                    os.makedirs(New_path_sh)
                if exists(New_path):  
                    shutil.move(File_name,New_path_sh)
                if platform == "win32":
                    shutil.make_archive(New_path,Arc,all_dirs[i],Names)
                elif platform == "linux2":
                    tar = tarfile.open(Names+'.tar.gz','w:gz')
                    tar.add(Names)
                    tar.close()
                else:
                    os.remove(File_name)
        File_name = ''
        num -= 1
        pos +=1
    files = os.listdir(all_dirs[i])
    for elem in files:
        if os.path.isdir(elem):
            if len(elem) > 4:
                shutil.rmtree(elem)
    i += 1


