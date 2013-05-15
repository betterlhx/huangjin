# change log
# 2013-5-5: 初始化本地文件，开始扫描时，将网页内容写入到本地文件，以免发送很多无用短信
# 2013-5-5: 自动初始化中金浏览器。并增加浏览器初始化检查机制。 TODO:由于飞信有时需要输入验证码，没法做到完全初始化，以后优化吧。
# 2013-5-15: 自动初始化飞信浏览器。并增加浏览器初始化检查机制。 局部优化，防止Exception的抛出。保证最大程度的自动化
# 2013-5-15: 在开始执行前，关闭所有ie浏览器
require "watir"
require 'yaml'

# 常量定义
$sleep_time = 5; ## 暂停几秒的设置
$file_name = "livemsg.yaml";  ## 本地存储
$log_file = "log_file.txt";   ## 日志文件

system('taskkill /f /im iexplore.exe') ## 关闭所有ie浏览器，重新初始化
######### begin  初始化飞信浏览器，并检查是否初始化成功   #############
begin
  $feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/); ## 首先寻找飞信浏览器，如果找不到，则初始化
rescue Exception
  $feixin_browser= Watir::Browser.new;
  $feixin_browser.goto("https://webim.feixin.10086.cn/login.aspx");
  sleep $sleep_time; ## 停止2s
  $feinxin_login_frame = $feixin_browser.frame(:src,"https://webim.feixin.10086.cn/loginform.aspx");
  $feinxin_login_frame.text_field(:id=>"login_username").set("15158133460");
  $feinxin_login_frame.text_field(:id=>"login_pass").set("ab8891491");
  $feinxin_login_frame.a(:class=>"ln_btn_login").click;
  sleep $sleep_time; ## 暂停几秒，等飞信浏览器完全初始化成功
end
$feixin_browser = Watir::Browser.attach(:url,/webim.feixin.10086.cn/); ## 再次获得飞信浏览器的焦点
if ($feixin_browser.nil?) ## 检查策略
  return;
end
## 得到飞信的iframe
$feinxin_frame = $feixin_browser.frame(:src,"content/freeSms.htm?tabIndex=0");
if ($feinxin_frame.nil?) ## 检查策略
  return;
end
######## end 飞信浏览器初始化完毕 ########################

######## begin 初始化cnfol浏览器，并检查是否初始化成功 ##########
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
sleep $sleep_time; ## 稍微停顿几秒，等待内容的加载
if($cnfolBrowser.url != "http://cs.cnfol.com/gold/userTolivemsg.html?expertId=5607817") ## 检查策略
  return;
end
######## end 初始化cnfol浏览器，并检查是否初始化成功 ##########

# 发送短信息
def send_sms(message="")
  ## feixin variable
  $feinxin_frame.checkbox(:id,"sendToMe").set;
  $feinxin_frame.text_field(:id,"smsContent").set message;
  $feinxin_frame.link(:id,"submitBtn").click;

  sleep $sleep_time; ## 停止几秒
end

# 获取直播内容
def get_live_content()
  #$cnfolBrowser.refresh();
  #sleep $sleep_time; ## 停止2s

  live_content = Hash.new;
  $cnfolBrowser.div(:id =>"livemsgContent").divs(:class=>"clearfix Uline").each do |div|
    live_content.store(div.i.text, div.span.text);
  end

  return live_content;
end

# 把Hash写入文件
def write_file(live_content,file_name=$file_name)
  File.open(file_name,"w") do|io|
    YAML.dump(live_content,io)
  end
end

def write_log(log)
  log_file = open($log_file,"a");
  log_file.puts(log);
end

# 读取文件，返回Hash
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



# 初始化本地备份的内容
def init()
  begin
  live_content = get_live_content(); ## 获取网页的直播内容
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
  # 将直播内容存储到文件中
  write_file(live_content); # 存储文件
  send_sms("init completed, start scan...");
end

####### 初始化动作，将当前的直播内容写入日志文件 ####
init(); # 初始化本地备份的内容

# 无限循环
while true do
  begin
    live_content = get_live_content(); ## 获取网页的直播内容
    db_live_content = read_file(); ## 获取存储的直播内容

    ## 对比live_content和db_live_content
    ## 遍历live_content，判断key是否存在于db_live_content
    sms_content=""; ## 记录这次扫描短信的所有内容
    live_content.each do |k,v|
      unless(db_live_content.has_key?(k))  # unless和if相反
        sms_content = sms_content+ ">>" + k + " " +v;
        send_sms(k + " " +v); ## 发送飞信
      end
    end

    # 将直播内容存储到文件中
    unless(live_content.empty?)
      write_file(live_content); # 存储文件
    end

    ## 写入日志
    log = "time: "+Time.now.to_s + " SMS content: "+sms_content;
    write_log(log);
    puts log;

    sleep $sleep_time; # 休眠几秒
  rescue Exception => e
    write_log("Exception" + e.to_s);
    puts "Exception" + e.to_s;
  end
end