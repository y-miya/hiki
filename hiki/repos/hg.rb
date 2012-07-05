# $Id: hg.rb,v 1.1 2008-08-06 10:48:25 hiraku Exp $
# Copyright (C) 2008, KURODA Hiraku <hiraku{@}hinet.mydns.jp>
# This code is modified from "hiki/repos/git.rb" by Kouhei Sutou
# You can distribute this under GPL.

require 'hiki/repos/default'

module Hiki
  class ReposHg < ReposBase
    include Hiki::Util

    def commit(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("hg addremove -q #{escape(page)}".untaint)
        system("hg ci -m \"#{msg}\" #{escape(page)}".untaint)
      end
    end

    def delete(page, msg = default_msg)
      Dir.chdir("#{@data_path}/text") do
        system("hg rm #{escape(page)}".untaint)
        system("hg ci -m \"#{msg}\" #{escape(page)}".untaint)
      end
    end

    def rename(old_page, new_page)
      old_page = escape(old_page.untaint)
      new_page = escape(new_page.untaint)
      Dir.chdir("#{@data_path}/text") do
        raise ArgumentError, "#{new_page} has been already exist." if File.exist?(new_page)
        system("hg", "mv", "-q", old_page, new_page)
        system("hg", "commit", "-q", "-m", "'Rename #{old_page} to #{new_page}'")
      end
    end

    def get_revision(page, revision)
      r = ""
      Dir.chdir("#{@data_path}/text") do
        open("|hg cat -r #{revision.to_i-1} #{escape(page)}".untaint) do |f|
          r = f.read
        end
      end
      r
    end

    def revisions(page)
      require 'time'
      all_log = ''
      revs = []
      original_lang = ENV["LANG"]
      ENV["LANG"] = "C"
      Dir.chdir("#{@data_path}/text") do
        open("|hg log #{escape(page).untaint}") do |f|
          all_log = f.read
        end
      end
      ENV["LANG"] = original_lang
      all_log.split(/\n\n(?=changeset:\s+\d+:)/).each do |l|
        rev = l[/^changeset:\s+(\d+):.*$/, 1].to_i+1
        date = Time.parse(l[/^date:\s+(.*)$/, 1]).localtime.strftime('%Y/%m/%d %H:%M:%S')
        summary = l[/^summary:\s+(.*)$/, 1]
        revs << [rev, date, "", summary]
      end
      revs
    end
  end
end
