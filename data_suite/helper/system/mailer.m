% Description : 
%
% Algorithm : 
%
% Input :  
%
% Output : 
%
% Author : Nikolas Karalis
% Date : April 2013
%
% Dependencies : 
%
% Updates : 
%

function mailer(destination, title, text, username, password)
credentials = {username, password};

setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','E_mail',username);
setpref('Internet','SMTP_Username',credentials(1));
setpref('Internet','SMTP_Password',credentials(2));
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class','javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

% Send the mail
sendmail(destination,title,text);

% example
%mailer('nikolaskaralis@gmail.com','test','test1', 'herry.lab@gmail.com','herry.lab')