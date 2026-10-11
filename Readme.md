FRAME26  
===
Matlab analyze tool base on MatLab2026 for course Advanced Structural Theromn   
(2026 Autumn) 
---
Supervised by 
Assistant Professor Chun-Yu Ke


Programmer:  
C. H. Chen R15521239  
Jay Wu R15521221

#  Object structrue
>FRAME26(fileName)
>>Property
>>>FILENAME
TITLE
FUNIT
LUNIT
PRPGRAMMER
NNOD, NBC, NMAT, NSEC, ITP, NNE, IFORCE
NCO, NDN, NDE      
COOR
NFIX
EXLD
IDBC
VECTY
FEF
PROP
SECT
IPR

>>method
>>>readInput()

>>>drawStructure()

>>private methods
#  properties
``` MatLab

FILENAME
TITLE
FUNIT
LUNIT
PRPGRAMMER
NNOD, NBC, NMAT, NSEC, ITP, NNE, IFORCE
NCO, NDN, NDE      
COOR
NFIX
EXLD
IDBC
VECTY
FEF
PROP
SECT
IPR = [1,2,2,2,3,3; 2,2,3,3,3,6]

```
# Method and Instance
```
model = FRAME26(filename)
model.drawStructure()
```
```CMD
example of print up 1D beam
```
>FRAME26(file name)
>>initialize object with file and call readInput()

>drawStructure(FORMAT)
>>Draw Coordinated and members joints



# expection 
finish structure analyze method ...