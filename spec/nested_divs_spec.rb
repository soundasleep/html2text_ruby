# frozen_string_literal: true

require 'spec_helper'

describe Html2Text, 'nested divs' do
  it 'adds no line break for a div that has all the text of its parent div' do
    expect(Html2Text.convert('x<div><div>a</div></div>')).to eq("x\na")
    expect(Html2Text.convert('<b>x</b><div> <div>a</div> </div>')).to eq("x\na")
  end

  it 'ignores comments next to the div' do
    expect(Html2Text.convert('<span>x</span><div><div>a</div><!-- c --></div>')).to eq("x\na")
  end

  it 'adds a line break for a div with text next to it' do
    expect(Html2Text.convert('<span>x</span><div><div>a</div>b</div>')).to eq("x\n\na\nb")
  end

  it 'converts many sibling divs in linear time' do
    html = "<div>#{'<div>line</div>' * 50_000}</div>"

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    text = Html2Text.convert(html)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    expect(text.lines.size).to eq(50_000)
    # Took tens of seconds when the parent's text was computed for every div
    expect(elapsed).to be < 5
  end

  it 'converts many empty sibling divs in linear time' do
    html = "<div>#{'<div> </div>' * 50_000}x</div>"

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    text = Html2Text.convert(html)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

    expect(text).to eq('x')
    expect(elapsed).to be < 5
  end
end
