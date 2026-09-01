#let date = datetime(
  year: 2023,
  month: 5,
  day: 14,
)
#metadata((
  "title": "使用python爬取并分析疫情数据",
  "author": "dashuai009",
  description: "这是一种将C++更加现代的代码组织方式。 模块是一组源代码文件，独立于导入它们的翻译单元进行编译。",
  pubDate: "'Jul 08 2022'",
  subtitle: [python,疫情数据分析],
))<frontmatter>

#import "../__template/style.typ": conf
#show: conf

#outline()


= 数据获取
<数据获取>
选取#link("https://en.wikipedia.org/w/index.php?title=Template:COVID-19_pandemic_data")[wikipedia];上的疫情数据，总数据页如下

#figure(
  image("013/data0.png"),
  caption: [
    总数据页
  ],
)

每个国家的数据都可以从表格中解析出来，例如United
States的详细数据的地址为
#link("https://en.wikipedia.org/wiki/COVID-19_pandemic_in_the_United_States")[Unitedd States];。
具体数据可以从下图中的表格解析：

#figure(
  image("013/data1.png"),
  caption: [
    United States数据页
  ],
)

仔细分析之后我们可以写以下爬虫代码：

```python
import scrapy
from ..items import FordataItem

class mySpider(scrapy.spiders.Spider):
    name = "forData"

    def start_requests(self):
        beginUrl= "https://en.wikipedia.org/w/index.php?title=Template:COVID-19_pandemic_data"
        myHeader = {
            'Content-Type': 'application/json',
            'User-Agent':'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0'
        }
        #先爬出数据首页，找到有哪些国家
        yield scrapy.Request(url=beginUrl,callback=self.parseCountryUrl,headers=myHeader)
```

```python
    def parseCountryUrl(self,response):
        cnt=0
        for each in response.xpath('/html/body/div[3]/div[3]/div[5]/div[1]/div[4]/div[2]/table/tbody/tr'):
            countryName=each.xpath('th[2]/a/text()').get()
            countryUrl=each.xpath('th[2]/a/@href').extract()
            if(countryName!=None and len(countryUrl)>0):
                cnt=cnt+1
                print(countryName,countryUrl)
                countryDataUrl= "https://en.wikipedia.org"+countryUrl[0]
                myHeader = {
                    'Content-Type': 'application/json',
                    'User-Agent':'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:81.0) Gecko/20100101 Firefox/81.0'
                }
                yield scrapy.Request(url=countryDataUrl,headers=myHeader,callback=lambda response,name=countryName:self.parseCountryCase(response,name))
                #再分别爬取每个国家的数据
        print(cnt)

    def parseCountryCase(self,response,name):
        ct=0
        for tr in response.css('tr.mw-collapsible'):
            item=FordataItem()
            item['country']=name
            item['date']=tr.xpath('td[1]/text()').get()
            item['cases']=tr.xpath('td[3]/span[1]/text()').get()
            item['deaths']=tr.xpath('td[4]/span[1]/text()').get()
            #解析出每个国家的名字、日期、病例、死亡数
            if('2020' in item['date']):
                ct=ct+1
                yield(item)
        if(ct==0):
            print("没有单日数据的的国家：",name)
```

数据前几行如下：

#figure(
  image("013/data2.png", width: 90%),
  caption: [
    疫情数据
  ],
)

另外，这个网页上并没有人口总数的数据可以从#link("https://en.wikipedia.org/wiki/List_of_countries_and_dependencies_by_population");上继续爬取。

#figure(
  image("013/data3.png", width: 90%),
  caption: [
    国家人口对应表的数据来源
  ],
)

可以写出如下爬虫

```python
import scrapy
from ..items import ForpopulationItem

class mySpider(scrapy.spiders.Spider):
    name = "forPopulation"

    def start_requests(self):
        beginUrl= "https://en.wikipedia.org/wiki/List_of_countries_and_dependencies_by_population"
        myHeader = {
            'Content-Type': 'application/json',
            'User-Agent':'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0'
        }
        #网页请求
        yield scrapy.Request(url=beginUrl,callback=self.parsePopulation,headers=myHeader)

    def parsePopulation(self,response):
        for tr in response.xpath('/html/body/div[3]/div[3]/div[5]/div[1]/table/tbody/tr'):
            #数据解析
            item=ForpopulationItem()
            item['country']=tr.xpath('td[1]/a/text()').get()
            item['population']=tr.xpath('td[2]/text()').get()
            if(item['country'] and item['population']):
                item['population'].replace(',','')
                print(item)
                yield item
```

爬取结果如下

#figure(
  image("013/data4.png", width: 90%),
  caption: [
    国家人口对应表
  ],
)

= 数据分析和展示
<数据分析和展示>
== 数据读入和清洗
<数据读入和清洗>
从前面爬取的数据文件`myData.csv`和`population.csv`中读取数据。
对于疫情数据，将空值填充为0，只保留日起在`2020-11-30`到`2020-12-15`之间的数据。
将病例数`cases`和`deaths`格式转换为`int64`。 根据`country`和`date`
进行去重。

```python
import pandas
import numpy
import matplotlib
import matplotlib.pyplot as plt
from brokenaxes import brokenaxes
import seaborn

org=pandas.read_csv('myData.csv')
org=org.fillna('0')
org['cases']=org['cases'].str.replace('\D+','').astype(int)
org['deaths']=org['deaths'].str.replace('\D+','').astype(int)
org=org[org['date']<'2020-12-16']
org=org[org['date']>'2020-11-29']
org.drop_duplicates(subset = ['country','date'],keep='first',inplace=True)
myData=org
population=pandas.read_csv('population.csv')
population['population']=population['population'].str.replace('\D+','').astype(int)

print("收集到的",len(myData['country'].value_counts(dropna=False)),"个国家的数据")
```

收集到的 135 个国家的数据

```python
## 15天中，全球新冠疫情的总体变化趋势


####################################
#a) 15 天中,全球新冠疫情的总体变化趋势#
####################################

print("\n\n====15 天中,全球新冠疫情的总体变化趋势======")

#这十六天内的全球累计病例
totalCase=[0]*16

#这16天内的全球死亡累计病例
totalDeaths=[0]*16

#December表示日期，用字符串存储，方便图例生成
December=['']*16

#根据国家进行分组，全球数量=个国家数量之和，计算累计病例和死亡病例
casesSumByDay=myData.pivot_table(index='date',values=['cases'],aggfunc=sum)
deathsSumByDay=myData.pivot_table(index='date',values=['deaths'],aggfunc=sum)

December[0]='2020-11-30'
totalCase[0]=casesSumByDay.loc['2020-11-30']['cases']
totalDeaths[0]=deathsSumByDay.loc['2020-11-30']['deaths']

for i in range(1,16):
December[i]='2020-12-'+('0' if i<10 else '')+str(i)
totalCase[i]=casesSumByDay.loc[December[i]]['cases']
totalDeaths[i]=deathsSumByDay.loc[December[i]]['deaths']

print("11-30到12-15感染病例：",totalCase)
print("11-30到12-15死亡病例：",totalDeaths)

# matplotlib绘图显示中文

plt.rcParams["font.family"]="SimHei"

#画图部分
mycolors = ['tab:red', 'tab:blue']
fig, ax = plt.subplots(1,1,figsize=(16, 9), dpi= 300)
x  = December
y = numpy.vstack([totalDeaths,totalCase])
labs=['累积死亡数','累积感染病例']
ax = plt.gca()
ax.stackplot(x, y, labels=labs, colors=mycolors, alpha=0.8)
plt.title("15 天中,全球新冠疫情的总体变化趋势")
ax.legend(fontsize=10, ncol=4)
plt.xticks(rotation=30,fontsize=10)  # 这里是调节横坐标的倾斜度
plt.gca().spines["top"].set_alpha(0)
plt.gca().spines["bottom"].set_alpha(.3)
plt.gca().spines["right"].set_alpha(0)
plt.gca().spines["left"].set_alpha(.3)
plt.savefig('a.png')
```

```text
====15 天中,全球新冠疫情的总体变化趋势======
11-30到12-15感染病例： [58806605, 59867806, 59924956, 60557860, 61163129, 59527002, 60033395, 62585050, 62008006, 63602677, 65008985, 65672468, 63968990, 64505434, 67261669, 68293227]
11-30到12-15死亡病例： [1471087, 1492594, 1494629, 1506452, 1517510, 1475608, 1482627, 1541590, 1516612, 1564328, 1576069, 1588076, 1541701, 1549901, 1611817, 1633944]
```

#figure(
  image("013/a.png", width: 100%),
  caption: [
    15 天中,全球新冠疫情的总体变化趋势
  ],
)

== 累计确诊数排名前 20 的国家名称及其数量
<累计确诊数排名前-20-的国家名称及其数量>
```python
####################################################
#b) 累计确诊数排名前 20 的国家名称及其数量;           #
####################################################
print("\n\n=======累计确诊数排名前 20 的国家名称及其数量=========")

#总的累计数量只需要看最后一天的数量
casesMaxByCountry=myData.pivot_table(index='country',values=['cases'],aggfunc=max)
casesMaxByCountry=casesMaxByCountry.sort_values('cases', ascending=False)

print(casesMaxByCountry.head(20))
```
输出结果：
```text
=======累计确诊数排名前 20 的国家名称及其数量=========
cases
country
United States   16022297
India            9906165
Brazil           6970034
Russia           2707945
France           2391447
Turkey           1898447
United Kingdom   1888116
Italy            1870576
Spain            1762212
Argentina        1510186
Colombia         1444646
Germany          1351510
Mexico           1267202
Poland           1147446
Iran             1123474
Peru              987675
Ukraine           919704
South Africa      873679
Indonesia         629429
Netherlands       628577
```

== 15 天中，每日新增确诊数累计排名前 10 个国家的每日新增确诊数据的曲线图
<天中每日新增确诊数累计排名前-10-个国家的每日新增确诊数据的曲线图>
```python
##########################################################################
#c）15 天中，每日新增确诊数累计排名前 10 个国家的每日新增确诊数据的曲线图;     #
##########################################################################
mycolors=['tab:blue','tab:orange','tab:green','tab:red','tab:purple','tab:brown','tab:pink','tab:gray','tab:olive','tab:cyan']
plt.clf()

#每个国家的12-1之前的累计数量
casesMinByCountry=myData.pivot_table(index='country',values=['cases'],aggfunc=min)

#每个国家12-1到12-15的新增数量
decCaseMaxByCountry=(casesMaxByCountry-casesMinByCountry).sort_values('cases', ascending=False)

cnt=0
countryCName=[]
figC=[0]*10
for index,row in decCaseMaxByCountry.iterrows():
cnt=cnt+1
countryCName.append(index)
yi=myData[myData['country']==index]['cases'].tolist()
for j in range(15,0,-1):#得到每日变化数据
yi[j]=yi[j]-yi[j-1]
figC[cnt-1],=plt.plot(December[1:],yi[1:],color=mycolors[cnt-1],linewidth=2.0,linestyle='-.')
if(cnt>=10):#只保留前十个国家
break

plt.title("每日新增确诊排名前 10 的国家的数据曲线图")
plt.legend(handles=figC,labels=countryCName)
plt.savefig('c.png')
```

#figure(
  image("013/c.png", width: 100%),
  caption: [
    每日新增确诊排名前 10 的国家的数据曲线图
  ],
)

== 累计确诊人数占国家总人口比例最高的 10 个国家
<累计确诊人数占国家总人口比例最高的-10-个国家>
```python
################################################
#d） 累计确诊人数占国家总人口比例最高的 10 个国家  #
################################################
print("\n\n=====累计确诊人数占国家总人口比例最高的 10 个国家======")

#这会用到populaton.csv的数据
#累计确诊比例
casesRatio=[]
for index,row in casesMaxByCountry.iterrows():
tmp=population[population['country']==index]['population']
if(len(tmp)>0):#这里需要注意没有人口数据的国家
casesRatio.append({'casesRatio':row['cases']/tmp.iloc[0],'name':index})

#升序排序取最后10个
casesRatio.sort(key=lambda x:x['casesRatio'])
for i in casesRatio[-1:-10:-1]:
print(i)
```
结果如下：
```text
=====累计确诊人数占国家总人口比例最高的 10 个国家======
{'casesRatio': 0.09561146718594844, 'name': 'Andorra'}
{'casesRatio': 0.06748037079864816, 'name': 'Luxembourg'}
{'casesRatio': 0.05548972112860494, 'name': 'Czech Republic'}
{'casesRatio': 0.05271911310260917, 'name': 'Belgium'}
{'casesRatio': 0.05243676244828293, 'name': 'Georgia'}
{'casesRatio': 0.05198869490976536, 'name': 'Qatar'}
{'casesRatio': 0.04872524937150579, 'name': 'Moldova'}
{'casesRatio': 0.04842282774074547, 'name': 'United States'}
{'casesRatio': 0.046797668330376366, 'name': 'Slovenia'}
```

== 死亡率（累计死亡人数/累计确诊人数）最低的 10 个国家
<死亡率累计死亡人数累计确诊人数最低的-10-个国家>
```python
#########################################################
#e) 死亡率(累计死亡人数/累计确诊人数)最低的 10 个国家;      #
#########################################################
print("\n\n====死亡率(累计死亡人数/累计确诊人数)最低的 10 个国家=======")

#每个国家死亡人数
deathsMaxByCountry=myData.pivot_table(index='country',values=['deaths'],aggfunc=max)
#每个国家的死亡率
deathsRatio=deathsMaxByCountry.rename(columns={'deaths':'deathsRatio'})
deathsRatio=deathsRatio/casesMaxByCountry.rename(columns={'cases':'deathsRatio'})
print((deathsRatio.sort_values('deathsRatio')).head(10))
```
结果如下：
```text
====死亡率(累计死亡人数/累计确诊人数)最低的 10 个国家=======
deathsRatio
country
Seychelles                           0.000000
Guyana                               0.000000
Saint Lucia                          0.000000
Faroe Islands                        0.000000
Saint Kitts and Nevis                0.000000
Falkland Islands                     0.000000
Brunei                               0.000000
Dominica                             0.000000
Saint Vincent and The Grenadines     0.000000
Singapore                            0.000497
```

== 用饼图展示各个国家的累计确诊人数的比例
<用饼图展示各个国家的累计确诊人数的比例>
```python

########################################
#f) 用饼图展示各个国家的累计确诊人数的比例#
########################################
print("\n\n=====各个国家的累计确诊人数的比例=======")

#把占比最大的几个国家列出来，直到这些国家占比超过75%，其他国家表示为other
cnt=0
figData=[]
for index,row in casesMaxByCountry.iterrows():
cnt=cnt+row['cases']
if cnt/totalCase[15]>0.75:
break
figData.append((index,row['cases']))
figData.append(('others',(totalCase[15]-cnt)))

#输出一下具体数据
print(figData)

#画图部分
plt.clf()
fig, ax = plt.subplots(figsize=(10, 5), ncols=2,dpi=300)
ax1, ax2 = ax.ravel()
patches, texts = ax1.pie(dict(figData).values(),
shadow=True,startangle=90,
labels=[ str(country)+','+str('%.2lf'%(tot*100/totalCase[15]))+'%' for country, tot in figData])
ax1.set_title('各个国家的累计确诊人数的比例')
ax2.axis('off')
ax2.legend(patches, [i for i,j in figData], loc='center left')
plt.tight_layout()
plt.savefig('f.png')
```

#figure(
  image("013/f.png", width: 100%),
  caption: [
    各个国家的累计确诊人数的比例
  ],
)

```text
=====各个国家的累计确诊人数的比例=======
[('United States', 16022297), ('India', 9906165), ('Brazil', 6970034), ('Russia', 2707945), ('France', 2391447), ('Turkey', 1898447), ('United Kingdom', 1888116), ('Italy', 1870576), ('Spain', 1762212), ('Argentina', 1510186), ('Colombia', 1444646), ('Germany', 1351510), ('Mexico', 1267202), ('others', 16154998)]
```

== 展示全球各个国家累计确诊人数的箱型图，有平均值
<展示全球各个国家累计确诊人数的箱型图有平均值>
```python
################################################
#g) 展示全球各个国家累计确诊人数的箱型图,要有平均值#
################################################
print("\n\n=====全球各个国家累计确诊人数的箱型图=====")

plt.clf()
fig, ax = plt.subplots(figsize=(5, 10),dpi=300)
#图中的黄点是平均数据值
seaborn.stripplot(y='cases',data={'cases':[totalCase[15]/135]}, color="orange", size=2.5)
seaborn.boxplot(data=casesMaxByCountry,linewidth=0.3,fliersize=1)
plt.title("全球各个国家累计确诊人数的箱型图")
plt.savefig('g.png')
```

#figure(
  image("013/g.png", width: 70%),
  caption: [
    全球各个国家累计确诊人数的箱型图
  ],
)

== 另外一些数据
<另外一些数据>
```python
15日新增确诊占累积确诊病例最小的20个国家

########################################

# 15日新增确诊占累积确诊病例最小的20个国家#

########################################
minRatio=(decCaseMaxByCountry/casesMaxByCountry).sort_values('cases')
print(minRatio.head(20))
```

```

cases
country
Comoros                0.000000
Singapore              0.002108
Australia              0.005099
Malawi                 0.008553
Isle of Man            0.010724
Suriname               0.012823
Brunei                 0.013158
Guernsey               0.013746
Sierra Leone           0.015912
Qatar                  0.017265
Ivory Coast            0.017774
New Zealand            0.019084
Bolivia                0.020363
Nepal                  0.022645
Benin                  0.024272
Peru                   0.024370
São Tomé and Príncipe  0.024752
Maldives               0.026706
Kuwait                 0.027776
Iceland                0.029580
```

= 全世界应对新冠疫情最好的10个国家
<全世界应对新冠疫情最好的10个国家>
注意：爬取的数据没有包含中国的数据。

显而易见的，感染人数过多（大于一百万）的国家应对疫情肯定不是最好的。
感染人数较少（小于100）也不需要考虑，这可能疫情并没有爆发，只是几个境外输入病例。
我们只考虑疫情严重的几个国家。这之后按照人口递减排序，取前10个。

```python

#####################
#最好的10个国家      #
#####################
print("\n\n======应对疫情最好的10个国家========")
good=[]
for index,rows in casesMaxByCountry.iterrows():
tmp=population[population['country']==index]['population']
if((100<rows['cases']<1000000) and len(tmp)>0):
good.append({'population':tmp.iloc[0],'name':index})

good.sort(key=lambda x:-x['population'])

for i in range(10):
print(good[i]['name'])
```

```
======应对疫情最好的10个国家========
Indonesia
Pakistan
Nigeria
Japan
Philippines
Ethiopia
Egypt
Vietnam
South Africa
Myanmar
```

= 预测分析
<预测分析>
== 预测方法
<预测方法>
采用线性回归的方法进行预测。
新冠疫情存在一定的趋势，但目前数据比较少（只有10天），可以假设不存在季节性。
这样，可以采用`线性回归`的方法进行预测。

== 预测程序
<预测程序>
```python

###################################

# 预测分析                        #

###################################

from sklearn import linear_model
regr = linear_model.LinearRegression()

# 拟合

regr.fit(numpy.array([i for i in range(10)]).reshape(-1, 1), totalCase[1:11])

# 得到直线的斜率、截距

a, b = regr.coef_, regr.intercept_

# 给出待预测日期

predictDate = numpy.array([i for i in range(10,16)]).reshape(-1,1)

#输出一下预测值
print(regr.predict(predictDate))

#画图部分
plt.clf()
fig, ax = plt.subplots(figsize=(16, 10),dpi=300)
plt.scatter(December, totalCase, color='blue')
plt.plot(December[1:], regr.predict(numpy.array([i for i in range(15)]).reshape(-1,1)), color='red', linewidth=4)
plt.savefig('i.png')
```

```text
======预测分析========
[64229138.06666667 64738456.51515152 65247774.96363637 65757093.41212121
66266411.86060607 66775730.30909091]
```


== 结果以及分析
<结果以及分析>
#figure(
  image("013/i.png"),
  caption: [
    预测分析
  ],
)

最后五天的数据拟合程度较好。

对于短期的数据，线性回归应该是较好的一种预测方法。
然而，再实际问题中，还需要考虑各种影响因素。
比如，各个国家政策的调整，病毒的变异等等。

= 代码网址
<代码网址>
#link("https://paste.ubuntu.com/p/KkGVZwhg7N/")[code]
