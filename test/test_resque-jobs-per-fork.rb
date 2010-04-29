require 'helper'

class SomeJob
  def self.perform(i)
    $SEQUENCE << "work_#{i}".to_sym
    puts 'working...'
    sleep(0.1)
  end
end

Resque.before_perform_jobs_per_fork do |worker|
  $SEQUENCE << "before_perform_jobs_per_fork".to_sym
end

Resque.after_perform_jobs_per_fork do |worker|
  $SEQUENCE << "after_perform_jobs_per_fork".to_sym
end

class TestResqueMultiJobFork < Test::Unit::TestCase
  def setup
    $SEQUENCE = []
    Resque.redis.flushdb
    ENV['JOBS_PER_FORK'] = '2'
    @worker = Resque::Worker.new(:jobs)
  end

  def test_one_job
    Resque::Job.create(:jobs, SomeJob, 1)
    @worker.work(0)
    assert_equal([:before_perform_jobs_per_fork, :work_1, :after_perform_jobs_per_fork], $SEQUENCE)
  end

  def test_two_jobs
    Resque::Job.create(:jobs, SomeJob, 1)
    Resque::Job.create(:jobs, SomeJob, 2)
    @worker.work(0)
    assert_equal([:before_perform_jobs_per_fork, :work_1, :work_2, :after_perform_jobs_per_fork], $SEQUENCE)
  end

  def test_three_jobs
    Resque::Job.create(:jobs, SomeJob, 1)
    Resque::Job.create(:jobs, SomeJob, 2)
    Resque::Job.create(:jobs, SomeJob, 3)
    @worker.work(0)
    assert_equal([:before_perform_jobs_per_fork, :work_1, :work_2, :after_perform_jobs_per_fork, 
      :before_perform_jobs_per_fork, :work_3, :after_perform_jobs_per_fork], $SEQUENCE)
  end

  def test_work_normally_if_env_var_set
    assert_nothing_raised(RuntimeError) do
      Resque::Job.create(:jobs, SomeJob, 1)
      @worker.work(0)
    end
  end

  def test_crash_if_no_env_var_set
    ENV.delete('JOBS_PER_FORK')
    assert_raise(RuntimeError) do
      Resque::Job.create(:jobs, SomeJob, 1)
      @worker.work(0)
    end
  end
end