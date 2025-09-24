function Sout = SetStructFields(Sin, Sfrom, FieldIndex, varargin)
%function Sout = SetStructFields(Sin, Sfrom, FieldIndex, StructIndex)
% setfields of array element at index StructIndex of structure Sin to 
% values from structure Sfrom at indexes FieldIndex
% Struct and Field Index are cell arrays
[StructIndex] = DefaultArgs(varargin,{{1}});

fields =fieldnames(Sfrom(1));

if isempty(Sin)
    Sout = struct();
else 
    Sout = Sin;
end
for k=1:length(fields)
    
%      A(1,2).name(3:5)=B invokes A=SUBSASGN(A,S,B) where S is 3-by-1
%     structure array with the following values:
%         S(1).type='()'       S(2).type='.'        S(3).type='()'
%         S(1).subs={1,2}      S(2).subs='name'     S(3).subs={3:5}
       S(1).type='()';       
       S(2).type='.'; 
       S(3).type='()';
       S(1).subs=StructIndex;      
       S(2).subs=fields{k}; 
       %S(3).subs=FieldIndex;
       Val = Sfrom.(fields{k});
       %if we are seting the value of matrix to element, then we need to
       %fix the index such that the non-singlular dimension of the matrix
       %are assigned first and the dimensions that correspond to FieldIndex
       %follow. also skips hte single dimension of the assigned matrix
       %(don't have to squeeze later)
       sz = size(Val);
       NewFieldIndex={};
       
       if max(sz)>1
           if sz(1)==1
               Val = shiftdim(Val);
               sz=sz(2:end);
           end
           for jj=1:length(sz)
               NewFieldIndex=cat(2,NewFieldIndex,[1:sz(jj)]);
           end
       end
       S(3).subs=cat(2,NewFieldIndex,FieldIndex);
       Sout = subsasgn(Sout, S, Val);
end
