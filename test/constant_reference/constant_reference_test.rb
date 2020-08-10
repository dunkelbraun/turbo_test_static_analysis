# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::Constants::ClassDefinition" do
  let(:subject) { TurboTest::StaticAnalysis::Constants }

  describe "singleton class definitions" do
    test "ignore singleton class on a class" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << Object
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[Whopper Object],
        source: source
      )
    end

    test "process singleton class on a top level class" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << ::Object
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA Object Object::singleton_class::ClassA],
        top_level_constants: %w[Object],
        constant_references: %w[Whopper],
        source: source
      )
    end

    test "ignore singleton class on a variable" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << a
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[Whopper],
        source: source
      )
    end

    test "ignore singleton class on a string" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << "a_string"
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[Whopper],
        source: source
      )
    end

    test "ignore singleton class on an array" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << [1,2,3,4]
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[Whopper],
        source: source
      )
    end

    test "singleton class on an instance of an object" do
      source = <<~RUBY
        module ModuleA
          a = Whopper
          class << Object.new
            class ClassA
            end
          end
          class << Regexp.new(/12/)
            class ClassA
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[Whopper Object Regexp],
        source: source
      )
    end
  end

  describe "method definition on singleton class" do
    test "parse singleton class when it's a top level singleton_class" do
      source = <<~RUBY
        def ModuleA.say_something
        end
        def self.say_something
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA self],
        top_level_constants: %w[],
        constant_references: %w[],
        source: source
      )
    end

    test "ignore singleton class when it's not a top level singleton class" do
      source = <<~RUBY
        module ModuleA
          def ModuleB.say_something
          end
          def self.say_something
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[ModuleB],
        source: source
      )
    end

    test "ignore singleton class when it's a var ref" do
      source = <<~RUBY
        module ModuleA
          mod = ModuleB
          def mod.say_something
            ClassA
          end
          another_mod = self
          def self.say_something
            ClassB
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA],
        top_level_constants: %w[],
        constant_references: %w[ModuleB ClassA ClassB],
        source: source
      )
    end
  end

  test "ignores non top level singleton class method definition" do
    source = <<~RUBY
      module ModuleA
        def ModuleB.say_something
        end
        something = ClassA
        def something.sound
          ClassB
        end
      end
      def ModuleC.say_something
      end
    RUBY

    assert_parsed(
      defined_classes: %w[ModuleA ModuleC],
      top_level_constants: %w[],
      constant_references: %w[ModuleB ClassA ClassB],
      source: source
    )
  end

  test "test defined classes, referenced top constants, and reference constants" do
    source = <<~RUBY
      module ::Pas #1
      end #2
      module Lamb #3
      end #4
      TopReferenceOne
      module ModuleA #5
        ANOTHER #6
        ::OKL #7
        ::ClassC #8
        ClassRef.include(AnotherClassRef) #9
        class ClassA #10
          class ClassB #11
            module ModuleB #12
            end #13
          end #14
          class ClassD
            LaPoste
          end
        end #15
        class ClassF
          ::HERO
          ::McFlurry.remove_toppings!
          class ::TopClass
            module TopClassModule
              ::Express
              LastConst
            end
          end
        end
      end #16
      TopReferenceTwo
    RUBY

    expected_classes = %w[
      Pas Lamb ModuleA ModuleA::ClassA ModuleA::ClassA::ClassD
      ModuleA::ClassA::ClassB ModuleA::ClassA::ClassB::ModuleB
      ModuleA::ClassF TopClass TopClass::TopClassModule
    ]
    assert_defined_classes(expected_classes, source)

    expected_referenced_top_constants = %w[
      OKL ClassC HERO Express TopReferenceOne TopReferenceTwo McFlurry
    ]
    assert_referenced_top_constants(expected_referenced_top_constants, source)

    expected_referenced_constants = %w[
      ANOTHER AnotherClassRef ClassRef LastConst LaPoste
    ]
    assert_referenced_constants(expected_referenced_constants, source)
  end

  describe "top level constants" do
    test "parse top level constants" do
      source = <<~RUBY
        ::ClassA
        ::ClassB.class_eval do
          1+1
        end
        ::ClassC.class_exec do
          1+1
        end
        ::ClassD.class_exec &:proc
        ::ClassE.class_exec(&:proc)
        ::ClassF.class_exec(1234, &:proc)
        ::ClassG.class_exec 1234, &:proc
        ::ClassH.send :timer_at, 1234
        ::ClassI.send(:timer_at, 1234)
        copy = ::ClassJ
        ::ClassK = "wewe"
        ::CONSTANT_A = "wawa"
        copy = ::ClassL
        copy = ::CONSTANT_B
        prepend ::ClassM
        send(:to_s, ::ClassN)
        lmda = -> { ::ModuleA.include(::ModuleB) }
        proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
      RUBY

      assert_parsed(
        defined_classes: %w[ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a class definition" do
      source = <<~RUBY
        class Whopper
          ::ClassA
          ::ClassB.class_eval do
            1+1
          end
          ::ClassC.class_exec do
            1+1
          end
          ::ClassD.class_exec &:proc
          ::ClassE.class_exec(&:proc)
          ::ClassF.class_exec(1234, &:proc)
          ::ClassG.class_exec 1234, &:proc
          ::ClassH.send :timer_at, 1234
          ::ClassI.send(:timer_at, 1234)
          copy = ::ClassJ
          ::ClassK = "wewe"
          ::CONSTANT_A = "wawa"
          copy = ::ClassL
          copy = ::CONSTANT_B
          prepend ::ClassM
          send(:to_s, ::ClassN)
          lmda = -> { ::ModuleA.include(::ModuleB) }
          proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a singleton_class #1" do
      source = <<~RUBY
        class Whopper
          class << self
            ::ClassA
            ::ClassB.class_eval do
              1+1
            end
            ::ClassC.class_exec do
              1+1
            end
            ::ClassD.class_exec &:proc
            ::ClassE.class_exec(&:proc)
            ::ClassF.class_exec(1234, &:proc)
            ::ClassG.class_exec 1234, &:proc
            ::ClassH.send :timer_at, 1234
            ::ClassI.send(:timer_at, 1234)
            copy = ::ClassJ
            ::ClassK = "wewe"
            ::CONSTANT_A = "wawa"
            copy = ::ClassL
            copy = ::CONSTANT_B
            prepend ::ClassM
            send(:to_s, ::ClassN)
            lmda = -> { ::ModuleA.include(::ModuleB) }
            proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a singleton_class #2" do
      source = <<~RUBY
        class << Whopper
          ::ClassA
          ::ClassB.class_eval do
            1+1
          end
          ::ClassC.class_exec do
            1+1
          end
          ::ClassD.class_exec &:proc
          ::ClassE.class_exec(&:proc)
          ::ClassF.class_exec(1234, &:proc)
          ::ClassG.class_exec 1234, &:proc
          ::ClassH.send :timer_at, 1234
          ::ClassI.send(:timer_at, 1234)
          copy = ::ClassJ
          ::ClassK = "wewe"
          ::CONSTANT_A = "wawa"
          copy = ::ClassL
          copy = ::CONSTANT_B
          prepend ::ClassM
          send(:to_s, ::ClassN)
          lmda = -> { ::ModuleA.include(::ModuleB) }
          proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a method definition #1" do
      source = <<~RUBY
        class Whopper
          def some_method
            ::ClassA
            ::ClassB.class_eval do
              1+1
            end
            ::ClassC.class_exec do
              1+1
            end
            ::ClassD.class_exec &:proc
            ::ClassE.class_exec(&:proc)
            ::ClassF.class_exec(1234, &:proc)
            ::ClassG.class_exec 1234, &:proc
            ::ClassH.send :timer_at, 1234
            ::ClassI.send(:timer_at, 1234)
            copy = ::ClassJ
            ::ClassK = "wewe"
            ::CONSTANT_A = "wawa"
            copy = ::ClassL
            copy = ::CONSTANT_B
            prepend ::ClassM
            send(:to_s, ::ClassN)
            lmda = -> { ::ModuleA.include(::ModuleB) }
            proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a method definition #2" do
      source = <<~RUBY
        class Whopper
          define_method :a_method do
            ::ClassA
            ::ClassB.class_eval do
              1+1
            end
            ::ClassC.class_exec do
              1+1
            end
            ::ClassD.class_exec &:proc
            ::ClassE.class_exec(&:proc)
            ::ClassF.class_exec(1234, &:proc)
            ::ClassG.class_exec 1234, &:proc
            ::ClassH.send :timer_at, 1234
            ::ClassI.send(:timer_at, 1234)
            copy = ::ClassJ
            ::ClassK = "wewe"
            ::CONSTANT_A = "wawa"
            copy = ::ClassL
            copy = ::CONSTANT_B
            prepend ::ClassM
            send(:to_s, ::ClassN)
            lmda = -> { ::ModuleA.include(::ModuleB) }
            proc = ::Proc.new { ::ModuleC.include(::ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a singleton class method definition" do
      source = <<~RUBY
        module ModuleA
          def ModuleB.say_something
            ::ClassA
          end
        end
        def ModuleC.say_something
          ::ClassB
        end
        ModuleD.singleton_class.define_method :a_method do
          ::ClassC
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleC],
        top_level_constants: %w[ClassA ClassB ClassC ModuleD],
        constant_references: %w[ModuleB],
        source: source
      )
    end

    test "parse top level constants inside a block" do
      source = <<~RUBY
        do_something do
          ::ModuleA.include(::ModuleX)
        end
        class Whopper
          do_something do
            ::ModuleB.include(::ModuleY)
          end
          def some_method
            do_something do
              ::ModuleC.include(::ModuleZ)
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[
          ModuleA ModuleB ModuleC
          ModuleX ModuleY ModuleZ
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse top level constants inside a lambda" do
      source = <<~RUBY
        lmda = -> { ::ModuleA.include(::ModuleX) }
        class Whopper
          lmda = -> { ::ModuleB.include(::ModuleY) }
          def some_method
            lmda = -> { ::ModuleC.include(::ModuleZ) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[
          ModuleA ModuleB ModuleC
          ModuleX ModuleY ModuleZ
        ],
        constant_references: %w[],
        source: source
      )
    end
  end

  describe "constant references" do
    test "parse constant references as top level constant" do
      source = <<~RUBY
        ClassA
        ClassB.class_eval do
          1+1
        end
        ClassC.class_exec do
          1+1
        end
        ClassD.class_exec &:proc
        ClassE.class_exec(&:proc)
        ClassF.class_exec(1234, &:proc)
        ClassG.class_exec 1234, &:proc
        ClassH.send :timer_at, 1234
        ClassI.send(:timer_at, 1234)
        copy = ClassJ
        ClassK = "wewe"
        CONSTANT_A = "wawa"
        copy = ClassL
        copy = CONSTANT_B
        prepend ClassM
        send(:to_s, ClassN)
        lmda = -> { ModuleA.include(ModuleB) }
        proc = Proc.new { ModuleC.include(ModuleD) }
      RUBY

      assert_parsed(
        defined_classes: %w[ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassL ClassK
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[

        ],
        source: source
      )
    end

    test "parse constant references inside a class definition" do
      source = <<~RUBY
        class Whopper
          ClassA
          ClassB.class_eval do
            1+1
          end
          ClassC.class_exec do
            1+1
          end
          ClassD.class_exec &:proc
          ClassE.class_exec(&:proc)
          ClassF.class_exec(1234, &:proc)
          ClassG.class_exec 1234, &:proc
          ClassH.send :timer_at, 1234
          ClassI.send(:timer_at, 1234)
          copy = ClassJ
          ClassK = "wewe"
          CONSTANT_A = "wawa"
          copy = ClassL
          copy = CONSTANT_B
          prepend ClassM
          send(:to_s, ClassN)
          lmda = -> { ModuleA.include(ModuleB) }
          proc = Proc.new { ModuleC.include(ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[],
        constant_references: %w[
          ClassA ClassB ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        source: source
      )
    end

    test "parse constant references inside a singleton class #1" do
      source = <<~RUBY
        class Whopper
          class << self
            ClassA
            ClassB.class_eval do
              1+1
            end
            ClassC.class_exec do
              1+1
            end
            ClassD.class_exec &:proc
            ClassE.class_exec(&:proc)
            ClassF.class_exec(1234, &:proc)
            ClassG.class_exec 1234, &:proc
            ClassH.send :timer_at, 1234
            ClassI.send(:timer_at, 1234)
            copy = ClassJ
            ClassK = "wewe"
            CONSTANT_A = "wawa"
            copy = ClassL
            copy = CONSTANT_B
            prepend ClassM
            send(:to_s, ClassN)
            lmda = -> { ModuleA.include(ModuleB) }
            proc = Proc.new { ModuleC.include(ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[],
        constant_references: %w[
          ClassA ClassB ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        source: source
      )
    end

    test "parse constant references inside a singleton class #2" do
      source = <<~RUBY
        class << Whopper
          ClassA
          ClassB.class_eval do
            1+1
          end
          ClassC.class_exec do
            1+1
          end
          ClassD.class_exec &:proc
          ClassE.class_exec(&:proc)
          ClassF.class_exec(1234, &:proc)
          ClassG.class_exec 1234, &:proc
          ClassH.send :timer_at, 1234
          ClassI.send(:timer_at, 1234)
          copy = ClassJ
          ClassK = "wewe"
          CONSTANT_A = "wawa"
          copy = ClassL
          copy = CONSTANT_B
          prepend ClassM
          send(:to_s, ClassN)
          lmda = -> { ModuleA.include(ModuleB) }
          proc = Proc.new { ModuleC.include(ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[],
        constant_references: %w[
          ClassA ClassB ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        source: source
      )
    end

    test "parse constant references inside a top level method definition #1" do
      source = <<~RUBY
        def some_method
          ClassA
          ClassB.class_eval do
            1+1
          end
          ClassC.class_exec do
            1+1
          end
          ClassD.class_exec &:proc
          ClassE.class_exec(&:proc)
          ClassF.class_exec(1234, &:proc)
          ClassG.class_exec 1234, &:proc
          ClassH.send :timer_at, 1234
          ClassI.send(:timer_at, 1234)
          copy = ClassJ
          ClassK = "wewe"
          CONSTANT_A = "wawa"
          copy = ClassL
          copy = CONSTANT_B
          prepend ClassM
          send(:to_s, ClassN)
          lmda = -> { ModuleA.include(ModuleB) }
          proc = Proc.new { ModuleC.include(ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[],
        source: source
      )
    end

    test "parse constant references inside a top level method definition #2" do
      source = <<~RUBY
        define_method :a_method do
          ClassA
          ClassB.class_eval do
            1+1
          end
          ClassC.class_exec do
            1+1
          end
          ClassD.class_exec &:proc
          ClassE.class_exec(&:proc)
          ClassF.class_exec(1234, &:proc)
          ClassG.class_exec 1234, &:proc
          ClassH.send :timer_at, 1234
          ClassI.send(:timer_at, 1234)
          copy = ClassJ
          ClassK = "wewe"
          CONSTANT_A = "wawa"
          copy = ClassL
          copy = CONSTANT_B
          prepend ClassM
          send(:to_s, ClassN)
          lmda = -> { ModuleA.include(ModuleB) }
          proc = Proc.new { ModuleC.include(ModuleD) }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassB],
        top_level_constants: %w[
          ClassA ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        constant_references: %w[
        ],
        source: source
      )
    end

    test "parse constant references inside a method definition #1" do
      source = <<~RUBY
        class Whopper
          def some_method
            ClassA
            ClassB.class_eval do
              1+1
            end
            ClassC.class_exec do
              1+1
            end
            ClassD.class_exec &:proc
            ClassE.class_exec(&:proc)
            ClassF.class_exec(1234, &:proc)
            ClassG.class_exec 1234, &:proc
            ClassH.send :timer_at, 1234
            ClassI.send(:timer_at, 1234)
            copy = ClassJ
            ClassK = "wewe"
            CONSTANT_A = "wawa"
            copy = ClassL
            copy = CONSTANT_B
            prepend ClassM
            send(:to_s, ClassN)
            lmda = -> { ModuleA.include(ModuleB) }
            proc = Proc.new { ModuleC.include(ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[],
        constant_references: %w[
          ClassA ClassB ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        source: source
      )
    end

    test "parse constant references inside a method definition #2" do
      source = <<~RUBY
        class Whopper
          define_method :a_method do
            ClassA
            ClassB.class_eval do
              1+1
            end
            ClassC.class_exec do
              1+1
            end
            ClassD.class_exec &:proc
            ClassE.class_exec(&:proc)
            ClassF.class_exec(1234, &:proc)
            ClassG.class_exec 1234, &:proc
            ClassH.send :timer_at, 1234
            ClassI.send(:timer_at, 1234)
            copy = ClassJ
            ClassK = "wewe"
            CONSTANT_A = "wawa"
            copy = ClassL
            copy = CONSTANT_B
            prepend ClassM
            send(:to_s, ClassN)
            lmda = -> { ModuleA.include(ModuleB) }
            proc = Proc.new { ModuleC.include(ModuleD) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[],
        constant_references: %w[
          ClassA ClassB ClassC ClassD ClassE ClassF
          ClassG ClassH ClassI ClassJ ClassK ClassL
          ClassM ClassN
          ModuleA ModuleB ModuleC ModuleD
          Proc
          CONSTANT_A CONSTANT_B
        ],
        source: source
      )
    end

    test "parse constant reference inside a singleton class method definition" do
      source = <<~RUBY
        module ModuleA
          def ModuleB.say_something
            ClassA
          end
          ModuleC.singleton_class.define_method :a_method do
            ClassB
          end
        end
        def ModuleD.say_something
          ClassC
        end
        ModuleE.singleton_class.define_method :a_method do
          ClassE
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleD],
        top_level_constants: %w[ModuleE],
        constant_references: %w[ModuleB ModuleC ClassA ClassB ClassC ClassE],
        source: source
      )
    end

    test "parse constant references inside a block" do
      source = <<~RUBY
        do_something do
          ModuleA.include(ModuleX)
        end
        class Whopper
          do_something do
            ModuleB.include(ModuleY)
          end
          def some_method
            do_something do
              ModuleC.include(ModuleZ)
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[ModuleA ModuleX],
        constant_references: %w[
          ModuleB ModuleC
          ModuleY ModuleZ
        ],
        source: source
      )
    end

    test "parse constant references inside a lambda" do
      source = <<~RUBY
        lmda = -> { ModuleA.include(ModuleX) }
        class Whopper
          lmda = -> { ModuleB.include(ModuleY) }
          def some_method
            lmda = -> { ModuleC.include(ModuleZ) }
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[Whopper],
        top_level_constants: %w[ModuleA ModuleX],
        constant_references: %w[
          ModuleB ModuleC
          ModuleY ModuleZ
        ],
        source: source
      )
    end
  end

  describe "module definition" do
    test "parse module definitions" do
      source = <<~RUBY
        module ::ModuleA
        end
        module ModuleB
          module ::ModuleC
          end
        end
        module ModuleD
          class ClassA
            class ClassB
              module ModuleE
              end
            end
            class ModuleF
              def self.a_method
              end
            end
          end
          class ModuleG
            class ::ClassC
              module ModuleH
              end
            end
            module ModuleI
              class << self
                class ClassD
                end
                class ::ClassE
                end
                class << self
                  class ClassF
                  end
                  class ::ClassG
                  end
                end
              end
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[
          ModuleA ModuleB ModuleC
          ModuleD ModuleD::ClassA ModuleD::ClassA::ClassB ModuleD::ClassA::ClassB::ModuleE
          ModuleD::ClassA::ModuleF
          ClassC ClassC::ModuleH
          ModuleD::ModuleG ModuleD::ModuleG::ModuleI
          ModuleD::ModuleG::ModuleI::singleton_class::ClassD
          ClassE
          ModuleD::ModuleG::ModuleI::singleton_class::singleton_class::ClassF
          ClassG
        ],
        top_level_constants: %w[],
        constant_references: %w[],
        source: source
      )
    end

    test "modules defined in new class blocks are top level modules" do
      source = <<~RUBY
        Proc.new do
          module ModuleA
          end
        end
        hello = Class.new do
          module ModuleB
          end
        end
        world = Class.new {
          module ModuleC
          end
        }
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleB ModuleC],
        top_level_constants: %w[Proc Class],
        constant_references: %w[],
        source: source
      )
    end

    test "modules defined in block" do
      source = <<~RUBY
        module ModuleA
          Proc.new do
            module ModuleB
            end
          end
        end
      RUBY
      assert_parsed(
        defined_classes: %w[ModuleA ModuleA::ModuleB],
        top_level_constants: %w[],
        constant_references: %w[Proc],
        source: source
      )
    end

    test "modules defined in class_eval with block  #1" do
      source = <<~RUBY
        module ModuleA
          class_eval do
            module ModuleB
            end
          end
        end
        some_class.class_eval do
          module ModuleC
            class_eval do
              module ModuleD
              end
            end
          end
        end
        ModuleE.class_eval do
          module ModuleF
          end
        end
        module ModuleG
          ModuleH.class_eval do
            module ModuleH
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleA::ModuleB ModuleE ModuleE::ModuleF ModuleG],
        top_level_constants: %w[],
        constant_references: %w[ModuleC ModuleC::ModuleD ModuleH ModuleH::ModuleH],
        source: source
      )
    end

    test "modules defined in class_eval with block  #2" do
      source = <<~RUBY
        module ModuleA
          class_eval {
            module ModuleB
            end
          }
        end
        some_class.class_eval {
          module ModuleC
            class_eval {
              module ModuleCC
              end
            }
          end
        }
        ModuleD.class_eval {
          module ModuleDD
          end
        }
        module ModuleF
          ModuleG.class_eval {
            module ModuleGG
            end
          }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleA::ModuleB ModuleD ModuleD::ModuleDD ModuleF],
        top_level_constants: %w[],
        constant_references: %w[ModuleC ModuleC::ModuleCC ModuleG ModuleG::ModuleGG],
        source: source
      )
    end

    test "modules defined in module_eval with block" do
      source = <<~RUBY
        module ModuleA
          module_eval do
            module ModuleB
            end
          end
        end
        some_class.module_eval do
          module ModuleC
            module_eval do
              module ModuleCC
              end
            end
          end
        end
        ModuleD.module_eval do
          module ModuleDD
          end
        end
        class ModuleF
          ModuleG.module_eval do
            module ModuleGG
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ModuleA ModuleA::ModuleB ModuleD ModuleD::ModuleDD ModuleF],
        top_level_constants: %w[],
        constant_references: %w[ModuleC ModuleC::ModuleCC ModuleG ModuleG::ModuleGG],
        source: source
      )
    end
  end

  describe "class definition" do
    test "parse class definitions" do
      source = <<~RUBY
        module ::ModuleA
        end
        module ModuleB
          class ::ClassA
          end
        end
        module ModuleC
          class ClassB
            class ClassC
              module ModuleD
              end
            end
            class ClassD
              def self.a_method
              end
            end
          end
          class ClassE
            class ::ClassF
              module ModuleE
              end
            end
            module ModuleF
              class << self
                class ClassG
                end
                class ::ClassH
                end
                class << self
                  class ClassI
                  end
                  class ::ClassJ
                  end
                end
              end
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[
          ModuleA ModuleB
          ClassA
          ModuleC
          ModuleC::ClassB
          ModuleC::ClassB::ClassC ModuleC::ClassB::ClassC::ModuleD
          ModuleC::ClassB::ClassD
          ModuleC::ClassE
          ClassF
          ClassF::ModuleE
          ModuleC::ClassE::ModuleF
          ModuleC::ClassE::ModuleF::singleton_class::ClassG
          ClassH
          ModuleC::ClassE::ModuleF::singleton_class::singleton_class::ClassI
          ClassJ
        ],
        top_level_constants: %w[],
        constant_references: %w[],
        source: source
      )
    end

    test "classes defined in new class blocks are top level classes" do
      source = <<~RUBY
        Proc.new do
          class ClassA
          end
        end
        hello = Class.new do
          class ClassB
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassA ClassB],
        top_level_constants: %w[Proc Class],
        constant_references: %w[],
        source: source
      )
    end

    test "classes defined in block" do
      source = <<~RUBY
        Proc.new do
          class ClassA
          end
        end
      RUBY
      assert_parsed(
        defined_classes: %w[ClassA],
        top_level_constants: %w[Proc],
        constant_references: %w[],
        source: source
      )
    end

    test "classes defined in class_eval with block  #1" do
      source = <<~RUBY
        class ClassA
          class_eval do
            class ClassB
            end
          end
        end
        some_class.class_eval do
          class ClassC
            class_eval do
              module ModuleA
              end
            end
          end
        end
        ClassD.class_eval do
          class ClassE
          end
        end
        class ClassF
          ClassG.class_eval do
            class ClassH
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassA ClassA::ClassB ClassD ClassD::ClassE ClassF],
        top_level_constants: %w[],
        constant_references: %w[ClassC ClassC::ModuleA ClassG ClassG::ClassH],
        source: source
      )
    end

    test "classes defined in class_eval with block  #2" do
      source = <<~RUBY
        class ClassA
          class_eval {
            class ClassB
            end
          }
        end
        some_class.class_eval {
          class ClassC
            class_eval {
              module ModuleA
              end
            }
          end
        }
        ClassD.class_eval {
          class ClassE
          end
        }
        class ClassF
          ClassG.class_eval {
            class ClassH
            end
          }
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassA ClassA::ClassB ClassD ClassD::ClassE ClassF],
        top_level_constants: %w[],
        constant_references: %w[ClassC ClassC::ModuleA ClassG ClassG::ClassH],
        source: source
      )
    end

    test "classes defined in module_eval with block" do
      source = <<~RUBY
        class ClassA
          module_eval do
            class ClassB
            end
          end
        end
        some_class.module_eval do
          class ClassC
            module_eval do
              module ModuleA
              end
            end
          end
        end
        ClassD.module_eval do
          class ClassE
          end
        end
        class ClassF
          ClassG.module_eval do
            class ClassH
            end
          end
        end
      RUBY

      assert_parsed(
        defined_classes: %w[ClassA ClassA::ClassB ClassD ClassD::ClassE ClassF],
        top_level_constants: %w[],
        constant_references: %w[ClassC ClassC::ModuleA ClassG ClassG::ClassH],
        source: source
      )
    end
  end

  private

  def assert_defined_classes(expected_classes, source)
    builder = subject.parse(source)
    assert_equal expected_classes.sort, builder.defined_classes.sort
  end

  def assert_referenced_top_constants(expected_top_constants, source)
    builder = subject.parse(source)
    assert_equal expected_top_constants.sort, builder.referenced_top_constants.keys.sort
  end

  def assert_referenced_constants(expected_referenced_constants, source)
    builder = subject.parse(source)
    assert_equal expected_referenced_constants.sort, builder.referenced_constants.keys.sort
  end

  def assert_parsed(opts)
    assert_defined_classes(opts[:defined_classes], opts[:source])
    assert_referenced_top_constants(opts[:top_level_constants], opts[:source])
    assert_referenced_constants(opts[:constant_references], opts[:source])
  end
end
