# change log
# 2013-5-5: ��ʼ�������ļ�����ʼɨ��ʱ������ҳ����д�뵽�����ļ������ⷢ�ͺܶ����ö���
# 2013-5-5: �Զ���ʼ���н���������������������ʼ�������ơ� TODO:���ڷ�����ʱ��Ҫ������֤�룬û��������ȫ��ʼ�����Ժ��Ż��ɡ�
# 2013-5-15: �Զ���ʼ��������������������������ʼ�������ơ� �ֲ��Ż�����ֹException���׳�����֤���̶ȵ��Զ���
# 2013-5-15: �ڿ�ʼִ��ǰ���ر�����ie�����
require "watir"
require 'yaml'

# ��������
$sleep_time = 5; ## ��ͣ���������
$file_name = "livemsg.yaml";  ## ���ش洢
$log_file = "log_file.txt";   ## ��־�ļ�

system('taskkill /f /im iexplore.exe') ## �ر�����ie����������³�ʼ��
######### begin  ��ʼ�������������������Ƿ��ʼ���ɹ�   #############
begin
  $feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/); ## ����Ѱ�ҷ��������������Ҳ��������ʼ��
rescue Exception
  $feixin_browser= Watir::Browser.new;
  $feixin_browser.goto("https://webim.feixin.10086.cn/login.aspx");
  sleep $sleep_time; ## ֹͣ2s
  $feinxin_login_frame = $feixin_browser.frame(:src,"https://webim.feixin.10086.cn/loginform.aspx");
  $feinxin_login_frame.text_field(:id=>"login_username").set("15158133460");
  $feinxin_login_frame.text_field(:id=>"login_pass").set("ab8891491");
  $feinxin_login_frame.a(:class=>"ln_btn_login").click;
  sleep $sleep_time; ## ��ͣ���룬�ȷ����������ȫ��ʼ���ɹ�
end
$feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/); ## �ٴλ�÷���������Ľ���
if ($feixin_browser.nil?) ## ������
  return;
end
## �õ����ŵ�iframe
$feinxin_frame = $feixin_browser.frame(:src,"content/freeSms.htm?tabIndex=0");
if ($feinxin_frame.nil?) ## ������
  return;
end
######## end �����������ʼ����� ########################

######## begin ��ʼ��cnfol�������������Ƿ��ʼ���ɹ� ##########
begin
  $cnfolBrowser = Watir::Browser.attach(:url,"http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817");
rescue Exception
  $cnfolBrowser = Watir::Browser.new;
  $cnfolBrowser.goto("http://passport.cnfol.com/accounts/Logout");
  $cnfolBrowser.text_field(:id=>"username").set("betterlhx");
  $cnfolBrowser.text_field(:id=>"password").set("hello1234");
  $cnfolBrowser.a(:id=>"login").click;
  $cnfolBrowser.goto("http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817");
end
sleep $sleep_time; ## ��΢ͣ�ټ��룬�ȴ����ݵļ���
if($cnfolBrowser.url != "http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817") ## ������
  return;
end
######## end ��ʼ��cnfol�������������Ƿ��ʼ���ɹ� ##########

# ���Ͷ���Ϣ
def send_sms(message="")
  ## feixin variable
  $feinxin_frame.checkbox(:id,"sendToMe").set;
  $feinxin_frame.text_field(:id,"smsContent").set message;
  $feinxin_frame.link(:id,"submitBtn").click;

  sleep $sleep_time; ## ֹͣ����
end

# ��ȡֱ������
def get_live_content()
  #$cnfolBrowser.refresh();
  #sleep $sleep_time; ## ֹͣ2s

  live_content = Hash.new;
  $cnfolBrowser.div(:id =>"livemsgContent").divs(:class=>"clearfix Uline").each do |div|
    live_content.store(div.i.text, div.span.text);
  end

  return live_content;
end

# ��Hashд���ļ�
def write_file(live_content,file_name=$file_name)
  File.open(file_name,"w") do|io|
    YAML.dump(live_content,io)
  end
end

def write_log(log)
  log_file = open($log_file,"a");
  log_file.puts(log);
end

# ��ȡ�ļ�������Hash
def read_file(file_name=$file_name)
  db_live_content = Hash.new;
  if (File.exist?(file_name))
    YAML.load_file(file_name).each do|i|
      key = i[0];
      value = i[1];
      db_live_content[key] = value;
    end
  end
  return db_live_content;
end



# ��ʼ�����ر��ݵ�����
def init()
  begin
  live_content = get_live_content(); ## ��ȡ��ҳ��ֱ������
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
  # ��ֱ�����ݴ洢���ļ���
  write_file(live_content); # �洢�ļ�
  send_sms("init completed, start scan...");
end

####### ��ʼ������������ǰ��ֱ������д����־�ļ� ####
init(); # ��ʼ�����ر��ݵ�����

# ����ѭ��
while true do
  begin
    live_content = get_live_content(); ## ��ȡ��ҳ��ֱ������
    db_live_content = read_file(); ## ��ȡ�洢��ֱ������

    ## �Ա�live_content��db_live_content
    ## ����live_content���ж�key�Ƿ������db_live_content
    sms_content=""; ## ��¼���ɨ����ŵ���������
    live_content.each do |k,v|
      unless(db_live_content.has_key?(k))  # unless��if�෴
        sms_content = sms_content+ ">>" + k + " " +v;
        send_sms(k + " " +v); ## ���ͷ���
      end
    end

    # ��ֱ�����ݴ洢���ļ���
    unless(live_content.empty?)
      write_file(live_content); # �洢�ļ�
    end

    ## д����־
    log = "time: "+Time.now.to_s + " SMS content: "+sms_content;
    write_log(log);
    puts log;

    sleep $sleep_time; # ���߼���
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
end