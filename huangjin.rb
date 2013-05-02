# To change this template, choose Tools | Templates
# and open the template in the editor.
require "watir"
require 'yaml'

## feixin global variable
$feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/);
$feinxin_frame = $feixin_browser.frame(:src,"content/freeSms.htm?tabIndex=0");

## cnfol global variable
$cnfolBrowser = Watir::Browser.attach(:url,"http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817");

# other
$sleep_time = 5; ## sleep time
$file_name = "huangjin.yaml";
$log_file = "log_file.txt";

# ���Ͷ���Ϣ
def send_sms(message="")
  ## feixin variable
  $feinxin_frame.checkbox(:id,"sendToMe").set;
  $feinxin_frame.text_field(:id,"smsContent").set message;
  $feinxin_frame.link(:id,"submitBtn").click;

  sleep $sleep_time; ## ֹͣ2s
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

# ����ѭ��
while true do
  begin
    live_content = get_live_content(); ## ��ȡ��ҳ��ֱ������
    db_live_content = read_file(); ## ��ȡ�洢��ֱ������

    ## �Ա�live_content��db_live_content
    ## ����live_content���ж�key�Ƿ������db_live_content
    smsContent=""; ## ��¼���ɨ����ŵ���������
    live_content.each do |k,v|
      unless(db_live_content.has_key?(k))  # unless��if�෴
        smsContent = smsContent+ ">>" + k + " " +v;
        send_sms(k + " " +v); ## ���ͷ���
      end
    end

    # ��ֱ�����ݴ洢���ļ���
    unless(live_content.empty?)
      write_file(live_content); # �洢�ļ�
    end

    ## д����־
    log = "time: "+Time.now.to_s + " SMS content: "+smsContent;
    write_log(log);
    puts log;

    sleep $sleep_time; # ���߼���
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
end

